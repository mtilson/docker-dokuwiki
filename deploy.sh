#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)"
ME="$( basename "${BASH_SOURCE[0]}" )"
ENV="${DIR}/.env"

test -f "$ENV" || { echo "$ME: error: .env file ($ENV) doesn't exist, exiting" ; exit 255 ; }
source <(cat $ENV | grep "PERSISTENT_DIR\|GIT_BACKUP_REPO_URL")

# DOKUWIKI_FE_RULE
# PERSISTENT_DIR *
# ACME_EMAIL
# DOCKER_DOMAIN
# BACKUP_USER_EMAIL
# GIT_BACKUP_REPO_URL *
# TZ
# MEMORY_LIMIT
# UPLOAD_MAX_SIZE
# OPCACHE_MEM_SIZE

GIT_BACKUP_REPO_SERVER=$(echo $GIT_BACKUP_REPO_URL | cut -d"@" -f2 | cut -d":" -f1)
test -n "$GIT_BACKUP_REPO_SERVER" ||
    { echo "$ME: error: invalid git remote url ($GIT_BACKUP_REPO_URL) defined in .env file ($ENV), exiting" ; exit 255 ; }

test -n "${PERSISTENT_DIR}" ||
    { echo "$ME: error: persistent dir variable (PERSISTENT_DIR) is not defined in .env file ($ENV), exiting" ; exit 255 ; }

sudo rm -fr "${PERSISTENT_DIR}/dokuwiki"
sudo mkdir -p "${PERSISTENT_DIR}/dokuwiki"
echo "$ME: log: recreated ${PERSISTENT_DIR}/dokuwiki"

sudo touch "${PERSISTENT_DIR}/acme.json"
sudo chmod 600 "${PERSISTENT_DIR}/acme.json"
echo "$ME: log: refreshed ${PERSISTENT_DIR}/acme.json"

cd $DIR
curl -sSL https://raw.githubusercontent.com/mtilson/dokuwiki/master/docker-compose.yml > docker-compose.yml

cat << _EOF
$ME: log: finished succesfully; run the following command to deploy containers and see their logs, use Ctrl-C to exit
docker-compose pull
docker-compose up -d
docker-compose logs -f
_EOF
