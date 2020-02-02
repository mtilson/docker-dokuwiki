## Note ##

* This is forked from [crazy-max/docker-dokuwiki](https://github.com/crazy-max/docker-dokuwiki)
* Backup to Git repo is based on [ericbarch/dockuwiki](https://github.com/ericbarch/dockuwiki)

## About ##

* It is [Docker image](https://hub.docker.com/r/mtilson/dokuwiki/) of [DokuWiki](https://www.dokuwiki.org/dokuwiki) behind [Traefik](https://github.com/containous/traefik)
* It uses [Traefik Docker image](https://github.com/containous/traefik-library-image) 
* Traefik is used as reverse proxy and for unattended creation/renewal of Let's Encrypt certificates

## Changes on 2020/01/15 ##

* Used before this change the common `docker-compose.yml` file is separated now to one for 'docuwiki' application container (`docker-compose.yml`) and dedicated one for 'traefik' container (`traefik/docker-compose.yml`)
* Due to this change you can now run 'traefik' container independently from 'dokuwiki' application container, which can be useful in case you already have 'traefik' container running as an edge proxy for other application containers
  * The only common configuration item which needs to be shared between 'traefik' container and its served application containers is the name of their common network defined by `COMMON_NETWORK` variable, see below
* The given 'traefik' `docker-compose.yml` file (`traefik/docker-compose.yml`) can be used as an example, in case you'd like to run 'dokuwiki' application container on fresh docker system, as described below

## Features ##

* Alpine Linux 3.9, Nginx, PHP 7.2, ACME Let's Encrypt via Traefik
* Tarball authenticity checked during building process
* OPCache enabled to store precompiled script bytecode in shared memory
* Data, configuration, plugins, and templates are backed up to a configured Git repo

## Environment variables ##

* Variables defined in `.env` file
  * `DOKUWIKI_TRAEFIK_FE_RULE`
    * `traefik` frontend rule
    * set default to `Host:wiki.example.com` in `docker-compose.yml`
    * used in `docker-compose.yml`, if not defined traffic will not be routed to `dokuwiki` container
    * example
      * `DOKUWIKI_TRAEFIK_FE_RULE=Host:wiki.example.com`
  * `PERSISTENT_DIR`
    * host persistent volume to store DockuWiki site data, ACME Let's Encrypt certificates, and a pravite key of your Git backup server account
    * set default to `/opt/docker/persistent` in `pre-deploy.sh`
    * set default to `/opt/docker/persistent` in `docker-compose.yml`
    * used by `pre-deploy.sh` to create host persistent volumes directory structure
    * used in `docker-compose.yml` and `traefik/docker-compose.yml` to define persistent volumes
    * example
      * `PERSISTENT_DIR=/opt/docker/persistent`
  * `ACME_EMAIL`
    * email address used for ACME (Let's Encrypt) registration
    * set default to `webmaster@example.com` in `traefik/docker-compose.yml`
    * used in `traefik/docker-compose.yml` to define `acme` email address, if not defined Let's Encrypt will not work correctly
    * example
      * `ACME_EMAIL=webmaster@example.com`
  * `DOCKER_DOMAIN`
    * default base domain name used for the frontend rules
    * set default to `docker.localhost` in `traefik/docker-compose.yml`
    * used in `traefik/docker-compose.yml` to define base domain name for frontend rules for hosts which are not full domain name
    * example
      * `DOCKER_DOMAIN=docker.localhost`
  * `COMMON_NETWORK`
    * name of the network common for `traefik` and its served containers
    * set default to `traefik-public-network` in `docker-compose.yml`
    * set default to `traefik-public-network` in `traefik/docker-compose.yml`
    * used in `docker-compose.yml` and `traefik/docker-compose.yml` to define the name of the docker bridged network for connectivity
    * example
      * `COMMON_NETWORK=traefik-public-network`
  * `BACKUP_USER_EMAIL`
    * backup user email address
    * used to mark generated public key to be added to the account used to access Git backup repo
    * used to configure Git global option `user.email` and derive `user.name` (as the part of the email address before '@' sign) for Git commands used to commit backup data to Git backup repo
    * used in container ENTRYPOINT
    * passed from `docker-compose` to container ENTRYPOINT
    * set default to `dokuwiki-backup@example.com` in `docker-compose.yml`
    * set default to `dokuwiki-backup@example.com` in container ENTRYPOINT if passed empty
    * example
      * `BACKUP_USER_EMAIL=dokuwiki-backup@example.com`
  * `GIT_BACKUP_REPO_URL`
    * [Git remote URL](https://help.github.com/en/articles/about-remote-repositories) of your repo on Git server to backup wiki content
      * Git associates a remote URL with a name, which is called `origin` by default, and for which you can get the URL with the following command (run within your repo directory)
        * `git remote get-url origin`
    * mandatory and validated in `pre-deploy.sh` script and in container ENTRYPOINT
    * passed by `docker-compose` to container ENTRYPOINT
    * example
      * `GIT_BACKUP_REPO_URL=git@bitbucket.org:username/reponame.git`
  * `TZ`
    * container timezone
    * used in container ENTRYPOINT
    * set default to `Europe/Luxembourg` in `docker-compose.yml`
    * passed from `docker-compose` to container ENTRYPOINT
    * set default to `UTC` in container ENTRYPOINT if passed empty
    * example
      * `TZ=Europe/Oslo`
* The following variable have defaults and used in container ENTRYPOINT. You can redefine them in `.env` and they will be passed as is to container ENTRYPOINT by `docker-compose`
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

## Volumes ##

* DokuWiki
  * `/data` - bind to host `${PERSISTENT_DIR}/dokuwiki/data` folder
    * folder that contains configuration, plugins, templates and data
  * `/root/.ssh` - bind to host `${PERSISTENT_DIR}/dokuwiki/root/.ssh` folder
    * folder that contains public/private keys, `config` and `known_hosts` files
    * you can place here the pravite key corresponding to a public key of your Git backup server account, name the file as `id_rsa`
* Traefik
  * `/acme.json` - bind to host `${PERSISTENT_DIR}/acme.json` file
    * file that contains ACME Let's Encrypt certificates

## Ports ##

* Traefik
  * `80` - HTTP port - redirects traffic to itself (Traefik) to HTTPS port (443)
  * `443` - HTTPS port - proxies traffic to DokuWiki to HTTP port (80)
* DokuWiki
  * `80` - HTTP port - serves DokuWiki wiki

## Installation ##

* On the fresh docker system (if you didn't run this installation procedure before), follow these steps:
  * Create project directory, `cd` to it, and run the following commands from within this project directory
  * Create `.env` file with the following environment variables, see the description and examples above
```bash
DOKUWIKI_TRAEFIK_FE_RULE=Host:wiki.example.com
PERSISTENT_DIR=/opt/docker/persistent
ACME_EMAIL=webmaster@example.com
DOCKER_DOMAIN=docker.localhost
BACKUP_USER_EMAIL=dokuwiki-backup@example.com
GIT_BACKUP_REPO_URL=git@bitbucket.org:username/reponame.git
COMMON_NETWORK=traefik-public-network
TZ=Europe/Oslo
MEMORY_LIMIT=
UPLOAD_MAX_SIZE=
OPCACHE_MEM_SIZE=
```
  * Download the pre-deployment script (`pre-deploy.sh`), make it executable, and run it
```bash
curl -sSL https://raw.githubusercontent.com/mtilson/dokuwiki/master/pre-deploy.sh > pre-deploy.sh
chmod +x pre-deploy.sh
./pre-deploy.sh
```
  * Provide access to your Git backup repo via SSH. You can do it the following way
    * Generate a public/pravite key pair
    * Place the private key to the host persistent volume as `${PERSISTENT_DIR}/dokuwiki/root/.ssh/id_rsa`
      * Make its permissions to be `read/write` only by `root`: 
        * `sudo chmod 600 ${PERSISTENT_DIR}/dokuwiki/root/.ssh/id_rsa`
    * Add the public key to the Git user account which has access to Git backup repo
      * `GIT_BACKUP_REPO_URL` variable defined above specifies *Git remote SSH URL address* used to access your Git backup repo
      * *Git remote SSH URL addresses* have the form `git@<gitserver>:<user>/<repo>.git`, which means that user account `<user>` has access to repository `<repo>` on Git server `<gitserver>`
      * To provide SSH access to your Git backup repo you have to add the generated public key to your `<user>` account on the `<gitserver>` server
        * See how to [set up an SSH key for BitBucket](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html)
        * See how to [connect to GitHub with SSH](https://help.github.com/articles/connecting-to-github-with-ssh/)
    * Create the SSH configuration file (`config`) in the host persistent volume as `${PERSISTENT_DIR}/dokuwiki/root/.ssh/config`
      * Put necessary SSH configuration to the above file, for example like the following
```bash
Host bitbucket.org
    StrictHostKeyChecking no
```
  * Run the following commands to deploy containers and see their logs (use `Ctrl-C` to exit)
```bash
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml pull
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml up -d
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml logs -f # to see the container logs in console; Ctrl-C to exit
```
  * If you didn't place the private key to the host persistent volume (as `${PERSISTENT_DIR}/dokuwiki/root/.ssh/id_rsa`), the container initialization script will generate a public/pravite key pair, store the generated keys in `${PERSISTENT_DIR}/dokuwiki/root/.ssh/`, and show the public key in the container log, waiting for the access to Git backup repo be provided - see the next point
  * If the container initialization script is not able to access Git backup repo, it will wait for 10 minutes (or till the moment the access is provided) checking once per minute for the access and asking you to add a public key. Look for the `Please add the public key ...` messages in the container log in console
  * On the first container run (after this installation procedure), fresh DokuWiki data will be `commited` to the configured Git backup repo. On the next container run, DokuWiki data from the Git backup repo will be `cloned/pulled` to the container `/data` volume
  * As script proceeds, point your browser to your wiki site URL to finish with DokuWiki installation wizard, fill in the form provided by the wizard, and click `Save`
  * The following message will appear in your browser
    * `The configuration was finished successfully. You may delete the install.php file now. ... `
  * Use `Ctrl-C` in console to exit from `docker-compose logs`, delete the `install.php` file with the following command:
    * `docker exec dokuwiki /bin/sh -c "rm -fr /var/www/install.php"`

## Next run ##

* If you did installation procedure before and just need to run existing 'dokuwiki' container, run the following command from the project directory (created during installation procedure):
```bash
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml pull
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml up -d
```

## Upgrade ##

* Use the the following commands to upgrade containers, it is recommended
```bash
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml down
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml pull
docker-compose -f docker-compose.yml -f traefik/docker-compose.yml up -d
```
* You can also upgrade DokuWiki automatically through its UI

## Backup and Restore ##

* All data in `/data` folder are periodically backed up to the provided Git backup repo
* Any time you run a container from [this image](https://hub.docker.com/r/mtilson/dokuwiki/) on any host with configured access to Git backup repo, DokuWiki data from the repo will be synced with the container's `/data` volume and host's `${PERSISTENT_DIR}/dokuwiki/data` folder. Use `pre-deploy.sh` script and the above *Installation* section to prepare host

## License ##

* MIT. See `LICENSE` for more details
