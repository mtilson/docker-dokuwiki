## Note

* This is forked from [crazy-max/docker-dokuwiki](https://github.com/crazy-max/docker-dokuwiki)
* Backup to Git repo is based on [ericbarch/dockuwiki](https://github.com/ericbarch/dockuwiki)

## About

* It is [DokuWiki](https://www.dokuwiki.org/dokuwiki) Docker image behind [Traefik](https://github.com/containous/traefik)
* Here is [Traefik Docker image](https://github.com/containous/traefik-library-image) compiled
* Traefik is used as reverse proxy and for unattended creation/renewal of Let's Encrypt certificates

## Features

* Alpine Linux 3.7, Nginx, PHP 7.1
* Tarball authenticity checked during building process
* OPCache enabled to store precompiled script bytecode in shared memory
* Data, configuration, plugins and templates are stored in an unique folder and commited to git repository
* Automatic backup to git repository

## Docker Compose

### Environment variables

* Mandatory variable, needs to be defined befor `docker-compose` run
    * `DW_HOST` : Your DockuWiki host name (mandatory, default to `wiki`)
    * `DW_DOMAIN` : Your DockuWiki domain name (mandatory, default to `example.com`)
    * `GIT_REMOTE_URL` : Git-URL of `git remote` for your repository, e.g.: "git@bitbucket.org:username/reponame.git" (mandatory, no defaults) 
    * `GIT_SERVER_NAME` : Domain name for git server from the above Git-URL, e.g.: "bitbucket.org" (mandatory, no defaults)
* Variable with defaults defined in Entrypoint shell script
    * `TZ` : The timezone assigned to the container (default to `UTC` in `Dockerfile`; set to `Europe/Luxembourg` in `docker-compose.yml`)
    * `MEMORY_LIMIT` : PHP memory limit (default to `256M`)
    * `UPLOAD_MAX_SIZE` : Upload max size (default to `16M`)
    * `OPCACHE_MEM_SIZE` : PHP OpCache memory consumption (default to `128`)

### Volumes

* DokuWiki
    * `/data` : folder that contains configuration, plugins, templates and data - it is bind to host `/opt/<host name>.<domain name>/data` folder
* Traefik
    * `/acme.json` : file that contains ACME Let's Encrypt certificates - it is bind to host `/opt/<host name>.<domain name>/acme.json` file

### Ports

* Traefik
    * `80` : HTTP port - redirects traffic to itself (Traefik) to HTTPS port (443)
    * `443` : HTTPS port - proxies traffic to DokuWiki to HTTP port (80)
* DokuWiki
    * `80` : HTTP port - serves DokuWiki wiki

### Install, Run, Upgrade

* Use `docker-compose` and the provided [docker compose file](docker-compose.yml) with the following _deployment commands_:

```bash
export DW_HOST=wiki                                             # to be changed to your host name
export DW_DOMAIN=example.com                                    # to be changed to your domain name
export GIT_REMOTE_URL="git@bitbucket.org:username/reponame.git" # to be changed to your repo git-url
export GIT_SERVER_NAME="bitbucket.org"                          # to be changed to your git server domain name from the above git-url

sudo mkdir -p /opt/${DW_HOST}.${DW_DOMAIN}
sudo touch /opt/${DW_HOST}.${DW_DOMAIN}/acme.json
sudo chmod 600 /opt/${DW_HOST}.${DW_DOMAIN}/acme.json

docker-compose pull
docker-compose up -d
docker-compose logs -f # to see the container logs; Ctrl-C to exit
```

#### Install

* Run the above _deployment commands_
* Wait for the following message from the container logs in the console:
    * `sleeping for 60 seconds to add the above key to git server account`
* Copy displayed public key and provide it to your git server
    * For example, see how to [Set up an SSH key](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html) for Bitbucket
* If you run installation procedure the first time, fresh DokuWiki data will be `commited` to your repository
* On the next run, DokuWiwi data from your repository will be cloned/pulled to the container `/data` volume
* As script proceeds, open your browser on `https://<host name>.<domain name>/install.php` to finish installation of DokuWiki through the wizard
* Fill in the form provided by the wizard and click `Save`
* As the following message appears `The configuration was finished successfully. You may delete the install.php file now. ... `, delete the install.php file:
    * `docker exec dokuwiki /bin/sh -c "rm -fr /var/www/install.php"`

#### Run

* Everything is run and ready after installation

#### Upgrade

* Use the above _deployment commands_ , it is recommended
* You can also upgrade DokuWiki automatically through its UI

## Backup

* All data in /data folder are backed up periodically to provided git repository

## License

* MIT. See `LICENSE` for more details
