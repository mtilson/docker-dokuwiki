## Note

* This is forked from [crazy-max/docker-dokuwiki](https://github.com/crazy-max/docker-dokuwiki)
* Backup to Git repo is based on [ericbarch/dockuwiki](https://github.com/ericbarch/dockuwiki)

## About

* It is [Docker image](https://hub.docker.com/r/mtilson/dokuwiki/) of [DokuWiki](https://www.dokuwiki.org/dokuwiki) behind [Traefik](https://github.com/containous/traefik)
* It uses [Traefik Docker image](https://github.com/containous/traefik-library-image) 
* Traefik is used as reverse proxy and for unattended creation/renewal of Let's Encrypt certificates

## Features

* Alpine Linux 3.8, Nginx, PHP 7.2, ACME Let's Encrypt via Traefik
* Tarball authenticity checked during building process
* OPCache enabled to store precompiled script bytecode in shared memory
* Data, configuration, plugins, and templates are backed up to a configured Git repo

## Environment variables

* Variables defined in `.env` file
    * `DW_FE_RULE`
        * `traefik` frontend rule
        * used in `docker-compose.yml` only, if not defined traffic will not be routed to `dokuwiki` container
        * example
            * `DW_FE_RULE=Host:wiki.example.com`
    * `DW_PERSISTENT_DIR`
        * host persistent volume to store DockuWiki site data, ACME Let's Encrypt certificates, and a pravite key of your backup Git server account
        * mandatory, used by `deploy.sh` to create host persistent volumes directory structure
        * used in `docker-compose.yml` to define persistent volumes
        * example
            * `DW_PERSISTENT_DIR=/opt/wiki.example.com`
    * `DW_DOMAIN`
        * DockuWiki site domain name
        * used in `docker-compose.yml` to define `acme` email address and docker domain, if not defined Let's Encrypt will not work correctly
        * passed from `docker-compose` to container ENTRYPOINT
        * set default to `example.com` in container ENTRYPOINT if passed empty
        * example
            * `DW_DOMAIN=example.com`
    * `DW_BACKUP_GIT_REMOTE_URL`
        * Git-URL of Git repo to backup wiki content
        * mandatory in container ENTRYPOINT, validated in `deploy.sh`
        * passed from `docker-compose` to container ENTRYPOINT
        * example
            * `DW_BACKUP_GIT_REMOTE_URL=git@bitbucket.org:username/reponame.git`
    * `TZ`
        * container timezone
        * used in container ENTRYPOINT only
        * set default to `Europe/Luxembourg` in `docker-compose.yml` if unset in `.env`
        * passed from `docker-compose` to container ENTRYPOINT
        * set default to `UTC` in container ENTRYPOINT if passed empty
        * example
            * `TZ=Europe/Oslo`
* Variable which have defaults and used in container ENTRYPOINT only. You can redefine them in `.env` and they will be passed as is to container ENTRYPOINT by `docker-compose`
    * `MEMORY_LIMIT`
        * PHP memory limit
        * default to `256M`
        * example
            * `MEMORY_LIMIT=256M`
    * `UPLOAD_MAX_SIZE`
        * Upload max size
        * default to `16M`
        * example
            * `UPLOAD_MAX_SIZE=16M`
    * `OPCACHE_MEM_SIZE`
        * PHP OpCache memory consumption
        * default to `128`
        * example
            * `OPCACHE_MEM_SIZE=128`

## Volumes

* DokuWiki
    * `/data` - bind to host `$DW_PERSISTENT_DIR/data` folder
        * folder that contains configuration, plugins, templates and data
    * `/root/.ssh` - bind to host `$DW_PERSISTENT_DIR/root/.ssh` folder
        * folder that contains public/private keys, config file, and known_hosts
        * you can place here the pravite key corresponding to a public key of your backup Git server account, name the file as `id_rsa`
* Traefik
    * `/acme.json` - bind to host `$DW_PERSISTENT_DIR/acme.json` file
        * file that contains ACME Let's Encrypt certificates

## Ports

* Traefik
    * `80` - HTTP port - redirects traffic to itself (Traefik) to HTTPS port (443)
    * `443` - HTTPS port - proxies traffic to DokuWiki to HTTP port (80)
* DokuWiki
    * `80` - HTTP port - serves DokuWiki wiki

## Installation

* Create `.env` file with the following envaronment variables, see the description and examples above
```bash
DW_FE_RULE=Host:wiki.example.com
DW_PERSISTENT_DIR=/opt/wiki.example.com
DW_DOMAIN=example.com
DW_BACKUP_GIT_REMOTE_URL=git@bitbucket.org:username/reponame.git
TZ=Europe/Oslo
MEMORY_LIMIT=
UPLOAD_MAX_SIZE=
OPCACHE_MEM_SIZE=
```
* Download the pre-deployment script (`deploy.sh`), make it executable, and run it
```bash
curl -sSL https://raw.githubusercontent.com/mtilson/dokuwiki/master/deploy.sh > deploy.sh
chmod +x deploy.sh
./deploy.sh
```
* You can provide access to your backup Git server in the following way
    * Generate a public/pravite key pair
    * Place the private key to the host persistent volume as `${DW_PERSISTENT_DIR}/root/.ssh/id_rsa`
    * Add the public key to your backup Git server account
        * See how to [set up an SSH key for BitBucket](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html)
        * See how to [connect to GitHub with SSH](https://help.github.com/articles/connecting-to-github-with-ssh/)
* Run the following commands to deploy containers and see their logs (use `Ctrl-C` to exit)
```bash
docker-compose pull
docker-compose up -d
docker-compose logs -f # to see the container logs in console; Ctrl-C to exit
```
* If you didn't place the private key to the host persistent volume (as `${DW_PERSISTENT_DIR}/root/.ssh/id_rsa`), the container initialization script will generate a public/pravite key pair, store the generated keys in `${DW_PERSISTENT_DIR}/root/.ssh/`, and show the public key in the container log
* If the container initialization script is not able to access backup Git server repo, it will wait for 10 minutes till the access is provided checking the access and asking you to add a public key once per minute. Look for the `Please add the public key ...` messages in the container log in console
* If you run installation procedure the first time, fresh DokuWiki data will be `commited` to the configured Git repo. On the next container run, DokuWiki data from the Git repo will be `cloned/pulled` to the container `/data` volume
* As script proceeds, point your browser to your wiki site URL to finish with DokuWiki installation wizard, fill in the form provided by the wizard, and click `Save`
* The following message will appear in your browser
    * `The configuration was finished successfully. You may delete the install.php file now. ... `
* Use `Ctrl-C` in console to exit from `docker-compose logs`, delete the `install.php` file with the following command:
    * `docker exec dokuwiki /bin/sh -c "rm -fr /var/www/install.php"`

## Upgrade

* Use the the following commands to upgrade containers, it is recommended
```bash
docker-compose down
docker-compose pull
docker-compose up -d
```
* You can also upgrade DokuWiki automatically through its UI

## Backup and Restore

* All data in `/data` folder are periodically backed up to the provided backup Git server repo
* Any time you run a container from [this image](https://hub.docker.com/r/mtilson/dokuwiki/) on any host with configured access to backup Git server repo, DokuWiki data from the backup repo will be synced with the container's `/data` volume and host's `$DW_PERSISTENT_DIR/data` folder. Use `deploy.sh` script and the above *Installation* section to prepare host

## License

* MIT. See `LICENSE` for more details
