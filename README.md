## Note

* This is forked from [crazy-max/docker-dokuwiki](https://github.com/crazy-max/docker-dokuwiki)
* Backup to Git repo is based on [ericbarch/dockuwiki](https://github.com/ericbarch/dockuwiki)

## About

* It is [DokuWiki](https://www.dokuwiki.org/dokuwiki) Docker image behind [Traefik](https://github.com/containous/traefik)
* Here is [Traefik Docker image](https://github.com/containous/traefik-library-image) compiled
* Traefik is used as reverse proxy and for unattended creation/renewal of Let's Encrypt certificates

## Features

* Alpine Linux 3.8, Nginx, PHP 7.2
* Tarball authenticity checked during building process
* OPCache enabled to store precompiled script bytecode in shared memory
* Data, configuration, plugins and templates are stored in an unique folder and commited to git repository
* Automatic backup to git repository

## Docker Compose

### Environment variables

* docker-compose variable defined in `.env` file 
    * `DW_FE_RULE`
        * `traefik` frontend rule
        * used in `docker-compose.yml`
        * e.g.: `DW_FE_RULE=Host:wiki.example.com`
    * `DW_PERSISTENT_DIR`
        * host persistent volume to store DockuWiki site data
        * e.g.: `DW_PERSISTENT_DIR=/opt/wiki.example.com`
    * `DW_DOMAIN`
        * DockuWiki site domain name
        * used in `docker-compose.yml` to define `acme` email address and docker domain
        * passed from `docker-compose` to container ENTRYPOINT script (default to `example.com` there if empty)
        * e.g.: `DW_DOMAIN=example.com`
    * `DW_BACKUP_GIT_REMOTE_URL`
        * Git-URL of Git repository to backup wiki cintent, e.g.: `git@bitbucket.org:username/reponame.git`
        * mandatory, passed from `docker-compose` to container ENTRYPOINT script
        * e.g.: `DW_BACKUP_GIT_REMOTE_URL=git@bitbucket.org:username/reponame.git`
* Variable with defaults defined in Entrypoint shell script
    * `TZ` : The timezone assigned to the container (default to `UTC` in `Dockerfile`; set to `Europe/Luxembourg` in `docker-compose.yml`)
    * `MEMORY_LIMIT` : PHP memory limit (default to `256M`)
    * `UPLOAD_MAX_SIZE` : Upload max size (default to `16M`)
    * `OPCACHE_MEM_SIZE` : PHP OpCache memory consumption (default to `128`)

### Volumes

* DokuWiki
    * `/data` : folder that contains configuration, plugins, templates and data - it is bind to host `$DW_PERSISTENT_DIR/data` folder
* Traefik
    * `/acme.json` : file that contains ACME Let's Encrypt certificates - it is bind to host `$DW_PERSISTENT_DIR/acme.json` file

### Ports

* Traefik
    * `80` : HTTP port - redirects traffic to itself (Traefik) to HTTPS port (443)
    * `443` : HTTPS port - proxies traffic to DokuWiki to HTTP port (80)
* DokuWiki
    * `80` : HTTP port - serves DokuWiki wiki

### Install, Run, Upgrade

* Use `docker-compose` and the provided [docker compose file](docker-compose.yml) with the following _deployment commands_:

```bash
https://raw.githubusercontent.com/mtilson/dokuwiki/master/deploy.sh

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
* On the next container run, DokuWiki data from your repository will be `cloned/pulled` to the container `/data` volume
* As script proceeds, point your browser to the following URL to finish with DokuWiki installation wizard
    * `https://<host name>.<domain name>/install.php`
* Fill in the form provided by the wizard and click `Save`
* The following message will appear in your browser:
    * `The configuration was finished successfully. You may delete the install.php file now. ... `
* Delete the `install.php` file with the following command:
    * `docker exec dokuwiki /bin/sh -c "rm -fr /var/www/install.php"`

#### Run

* Everything is run and ready after installation

#### Upgrade

* Use the above _deployment commands_ , it is recommended
* You can also upgrade DokuWiki automatically through its UI

## Backup

* All data in `/data` folder are backed up periodically to the provided git repository

## License

* MIT. See `LICENSE` for more details
