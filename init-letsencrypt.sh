#!/bin/bash

AUTO_YES=false
NO_WILDCARD=false

domains=("DOMAIN_BASE" "*.DOMAIN_BASE")
rsa_key_size=4096
data_path="./data/certbot"
email="info@DOMAIN_BASE" # Adding a valid address is strongly recommended
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

# Check for flags
for arg in "$@"
do
  case $arg in
    -y)
    AUTO_YES=true
    shift # Remove -y from processing
    ;;
    --no-wildcard)
    NO_WILDCARD=true
    domains=("MAINSUBDOMAIN.DOMAIN_BASE") # Only the Subdomain, not the wildcard
    shift # Remove --no-wildcard from processing
    ;;
    *)
    OTHER_ARGUMENTS+=("$1") # store invalid options
    shift # remove generic argument from processing
    ;;
  esac
done

# Get the first entry in domains array
first_domain=${domains[0]}

# Join domains with space for usage in commands
domains_string="${domains[*]}"

# Replace placeholders with user-provided values
grep -rl 'SUBDOMAIN_or_DOMAINBASE' . --exclude-dir=.git | xargs sed -i "s/SUBDOMAIN_or_DOMAINBASE/$first_domain/g"

if [ -d "$data_path" ]; then
  if [[ $AUTO_YES == true ]]; then
    echo "Automatically responding 'yes' to replace."
  else
    read -p "Existing data found for $first_domain. Continue and replace existing certificate? (y/N) " decision
    if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
      exit
    fi
  fi
fi

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

echo "### Creating dummy certificate for $first_domain ..."
path="/etc/letsencrypt/live/$first_domain"
mkdir -p "$data_path/conf/live/$first_domain"
docker compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo

echo "### Starting nginx ..."
docker compose up --force-recreate -d nginx
echo

echo "### Deleting dummy certificate for $first_domain ..."
docker compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$first_domain && \
  rm -Rf /etc/letsencrypt/archive/$first_domain && \
  rm -Rf /etc/letsencrypt/renewal/$first_domain.conf" certbot
echo

echo "### Requesting Let's Encrypt certificate for $domains_string ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker compose run --rm --entrypoint "\
  certbot certonly \
          $staging_arg \
          $email_arg \
          $domain_args \
          --rsa-key-size $rsa_key_size \
          --no-eff-email \
          --agree-tos \
          --force-renewal \
          --dns-cloudflare \
          --dns-cloudflare-credentials /etc/letsencrypt/cf.ini \
          --dns-cloudflare-propagation-seconds 30" certbot
echo

echo "### Reloading nginx ..."
docker compose exec nginx nginx -s reload
