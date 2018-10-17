#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)"
ME="$( basename "${BASH_SOURCE[0]}" )"
ENV="${DIR}/.env"

test -f "$ENV" || { echo "$ME: error: .env file ($ENV) doesn't exist, exiting" ; exit 255 ; }
source $ENV

# DW_FE_RULE
# DW_DOMAIN=
# DW_BACKUP_GIT_REMOTE_URL=
# DW_PERSISTENT_DIR=

DW_BACKUP_GIT_SERVER_NAME=$(echo $DW_BACKUP_GIT_REMOTE_URL | cut -d"@" -f2 | cut -d":" -f1)
test -n "$DW_BACKUP_GIT_SERVER_NAME" || 
    { echo "$ME: error: invalid git remote url ($DW_BACKUP_GIT_REMOTE_URL) defined in .env file ($ENV), exiting" ; exit 255 ; }

test -n "$DW_PERSISTENT_DIR" || 
    { echo "$ME: error: persistent dir variable (DW_PERSISTENT_DIR) is not defined in .env file ($ENV), exiting" ; exit 255 ; }

echo "$ME: log: recreate $DW_PERSISTENT_DIR"
sudo rm -fr "$DW_PERSISTENT_DIR"
sudo mkdir -p "$DW_PERSISTENT_DIR"
sudo touch "${DW_PERSISTENT_DIR}/acme.json"
sudo chmod 600 "${DW_PERSISTENT_DIR}/acme.json"

cat < _EOF
$ME: log: finished succesfully; run the following command to deploy containers and see their logs, use Ctrl-C to exit
docker-compose pull
docker-compose up -d
docker-compose logs -f
_EOF
