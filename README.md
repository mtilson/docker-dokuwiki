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

## Environment variables

* Variables defined in `.env` file
    * `DW_FE_RULE`
        * `traefik` frontend rule
        * used in `docker-compose.yml` only, if not defined traffic will not be routed to `dokuwiki` container
        * example: `DW_FE_RULE=Host:wiki.example.com`
    * `DW_PERSISTENT_DIR`
        * host persistent volume to store DockuWiki site data
        * mandatory, used by `deploy.sh` to create host persistent volumes directory structure
        * used in `docker-compose.yml` to define persistent volumes
        * example: `DW_PERSISTENT_DIR=/opt/wiki.example.com`
    * `DW_DOMAIN`
        * DockuWiki site domain name
        * used in `docker-compose.yml` to define `acme` email address and docker domain, if not defined Let's Encrypt will not work correctly
        * passed from `docker-compose` to container ENTRYPOINT
        * set default to `example.com` in container ENTRYPOINT if passed empty
        * example: `DW_DOMAIN=example.com`
    * `DW_BACKUP_GIT_REMOTE_URL`
        * Git-URL of Git repository to backup wiki content
        * mandatory in container ENTRYPOINT, validated in `deploy.sh`
        * passed from `docker-compose` to container ENTRYPOINT
        * example: `DW_BACKUP_GIT_REMOTE_URL=git@bitbucket.org:username/reponame.git`
    * `TZ`
        * container timezone
        * used in container ENTRYPOINT only
        * set default to `Europe/Luxembourg` in `docker-compose.yml` if unset in `.env`
        * passed from `docker-compose` to container ENTRYPOINT
        * set default to `UTC` in container ENTRYPOINT if passed empty
* Variable which have defaults and used in container ENTRYPOINT only. You can redefine them in `.env` and they will be passed as is to container ENTRYPOINT by `docker-compose`
    * `MEMORY_LIMIT`
        * PHP memory limit
        * default to `256M`
    * `UPLOAD_MAX_SIZE`
        * Upload max size
        * default to `16M`
    * `OPCACHE_MEM_SIZE`
        * PHP OpCache memory consumption
        * default to `128`

## Volumes

* DokuWiki
    * `/data` : folder that contains configuration, plugins, templates and data - it is bind to host `$DW_PERSISTENT_DIR/data` folder
* Traefik
    * `/acme.json` : file that contains ACME Let's Encrypt certificates - it is bind to host `$DW_PERSISTENT_DIR/acme.json` file

## Ports

* Traefik
    * `80` : HTTP port - redirects traffic to itself (Traefik) to HTTPS port (443)
    * `443` : HTTPS port - proxies traffic to DokuWiki to HTTP port (80)
* DokuWiki
    * `80` : HTTP port - serves DokuWiki wiki

## Installation

* Create `.env` file with the following envaronment variables, see the description and examples above:
```bash
DW_FE_RULE=Host:wiki.example.com
DW_PERSISTENT_DIR=/opt/wiki.example.com
DW_DOMAIN=example.com
DW_BACKUP_GIT_REMOTE_URL=git@bitbucket.org:username/reponame.git
TZ=Europe/Oslo        # optional
MEMORY_LIMIT=""       # optional
UPLOAD_MAX_SIZE=""    # optional
OPCACHE_MEM_SIZE=""   # optional
```
* Download the pre-deployment script (`deploy.sh`), make it executable, and run it
```bash
curl -sSL https://raw.githubusercontent.com/mtilson/dokuwiki/master/deploy.sh > deploy.sh
chmod +x deploy.sh
./deploy.sh
```
* Run the following commands to deploy containers and see their logs (use Ctrl-C to exit)
```bash
docker-compose pull
docker-compose up -d
docker-compose logs -f # to see the container logs; Ctrl-C to exit
```
* Wait for the following message from the `dokuwiki` container logs in the console:
    * `sleeping for 60 seconds to add the above key to git server account`
* Copy displayed public key and provide it to your git server
    * See how to [Set up an SSH key for BitBucket](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html)
    * Or see how to [Connect to GitHub with SSH](https://help.github.com/articles/connecting-to-github-with-ssh/)
* If you run installation procedure the first time, fresh DokuWiki data will be `commited` to your repository
* On the next container run, DokuWiki data from your repository will be `cloned/pulled` to the container `/data` volume
* As script proceeds, point your browser to your wiki site URL to finish with DokuWiki installation wizard
* Fill in the form provided by the wizard and click `Save`
* The following message will appear in your browser:
    * `The configuration was finished successfully. You may delete the install.php file now. ... `
* Use `Ctrl-C` to exit from `docker-compose logs` and delete the `install.php` file with the following command:
    * `docker exec dokuwiki /bin/sh -c "rm -fr /var/www/install.php"`

## Upgrade

* Use the the following commands to upgrade containers, it is recommended
```bash
docker-compose down
docker-compose pull
docker-compose up -d
```
* You can also upgrade DokuWiki automatically through its UI

## Backup

* All data in `/data` folder are backed up periodically (every 6 minutes) to the provided git repository

## License

* MIT. See `LICENSE` for more details
