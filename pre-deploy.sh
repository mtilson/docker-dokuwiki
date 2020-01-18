#!/usr/bin/env bash

ME="$( basename "${BASH_SOURCE[0]}" )" # script short name
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)" # script dir name

test -e "${DIR}/.env" && source <(cat "${DIR}/.env" | grep "^PERSISTENT_DIR=\|^GIT_BACKUP_REPO_URL=")
test -e "${PWD}/.env" && source <(cat "${PWD}/.env" | grep "^PERSISTENT_DIR=\|^GIT_BACKUP_REPO_URL=")
PERSISTENT_DIR=${PERSISTENT_DIR:-/opt/docker/persistent}

test -n "${GIT_BACKUP_REPO_URL}" || 
    { echo "$ME: error: variable GIT_BACKUP_REPO_URL is undefined (use '.env' file in the repo dir and/or in the script working dir to assign Git remote URL to GIT_BACKUP_REPO_URL variable); exiting" ;
      exit 255 ;
    }

GIT_BACKUP_REPO_SERVER=$(echo $GIT_BACKUP_REPO_URL | cut -d"@" -f2 | cut -d":" -f1)
test -n "$GIT_BACKUP_REPO_SERVER" ||
    { echo "$ME: error: invalid Git remote URL ($GIT_BACKUP_REPO_URL) defined using '.env' file in the repo dir and/or the script working dir; exiting" ;
      exit 255 ;
    }

sudo rm -fr "${PERSISTENT_DIR}/dokuwiki"
sudo mkdir -p "${PERSISTENT_DIR}/dokuwiki/root/.ssh"
sudo touch "${PERSISTENT_DIR}/acme.json"
sudo chmod 600 "${PERSISTENT_DIR}/acme.json"

(
cd $DIR
mkdir -p traefik
curl -sSL https://raw.githubusercontent.com/mtilson/dokuwiki/master/docker-compose.yml > docker-compose.yml
curl -sSL https://raw.githubusercontent.com/mtilson/dokuwiki/master/traefik/docker-compose.yml > traefik/docker-compose.yml
)

echo "We are ready. Go to the repo dir ($DIR) and use 'docker-compose -f docker-compose.yml -f traefik/docker-compose.yml CMD' command to proceed."
