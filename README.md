# Boilerplate for nginx-revProxy with Wildcard Let’s Encrypt using Cloudflare DNS on docker-compose

`init-letsencrypt.sh` fetches and ensures the renewal of a Let’s
Encrypt certificate for one Wildcard domain in a docker-compose
setup with nginx.
This is useful when you need to set up nginx as a reverse proxy for an
application.

## Important
**!** you should run this **directly in your Docker-Apps Folder** but be careful about **docker-compose.override.yml.MERGE**
this needs to be merged into your existing docker-compose.override.yml or renamed to be **docker-compose.override.yml** if it's not there yet.

"DOCKERSERVICEANDPORT" Example Value (server is the internal docker-service name found in docker-compose.yml)
http://server:9000

## Installation
1. [Install docker-compose](https://docs.docker.com/compose/install/#install-compose).

2.
```
git clone https://github.com/theoneandonly-vector/nginx-certbot.git
cd nginx-certbot/
chmod +x ./init-letsencrypt.sh
grep -rl DOMAIN_BASE . --exclude-dir=.git | xargs sed -i 's/DOMAIN_BASE/--------HERE you NEED to PUT your BASE-Domain--------/g'
grep -rl MAINSUBDOMAIN . --exclude-dir=.git | xargs sed -i 's/MAINSUBDOMAIN/--------HERE you NEED to PUT your MAIN SUB-Domain--------/g'
grep -rl API_TOKEN . --exclude-dir=.git | xargs sed -i 's/API_TOKEN/--------HERE you NEED to PUT your RESTRICTED CLOUDFLARE-API-TOKEN--------/g'
grep -rl DOCKERSERVICEANDPORT . --exclude-dir=.git | xargs sed -i 's/DOCKERSERVICEANDPORT/--------HERE you NEED to PUT your http://server:9000 ------/g'
cd ..
cp -rf nginx-certbot/* nginx-certbot/.* .
./init-letsencrypt.sh
docker-compose up -d
```

## License
All code in this repository is licensed under the terms of the `MIT License`. For further information please refer to the `LICENSE` file.
