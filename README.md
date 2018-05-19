## Note

* This is forked from [crazy-max/docker-dokuwiki](https://github.com/crazy-max/docker-dokuwiki)

## About

* It is [DokuWiki](https://www.dokuwiki.org/dokuwiki) Docker image behind [Traefik](https://github.com/containous/traefik)
* Here is [Traefik Docker image](https://github.com/containous/traefik-library-image) compiled
* Traefik is used as reverse proxy and for unattended creation/renewal of Let's Encrypt certificates

## Features

### Included

* Alpine Linux 3.7, Nginx, PHP 7.1
* Tarball authenticity checked during building process
* OPCache enabled to store precompiled script bytecode in shared memory
* Data, configuration, plugins and templates are stored in an unique folder

## Docker Compose

### Environment variables

* `TZ` : The timezone assigned to the container (default to `UTC`)
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
    * `80` : HTTP port - redirect traffic to itself (Traefik) to HTTPS port (443)
    * `443` : HTTPS port - proxies traffic to DokuWiki to HTTP port (80)
* DokuWiki
    * `80` : HTTP port - server DokuWiki wiki

### Install, Run, Upgrade

* Use docker-compose and the provided [docker compose file](docker-compose.yml) with the following _deployment commands_:

```bash
export DWHOST=dokuwiki # to be changed to your host name
export DWDOMAIN=example.com # to be changed to your domain name

test -d /opt/${DWHOST}.${DWDOMAIN} || sudo mkdir -p /opt/${DWHOST}.${DWDOMAIN}

sudo touch /opt/${DWHOST}.${DWDOMAIN}/acme.json
sudo chmod 600 /opt/${DWHOST}.${DWDOMAIN}/acme.json

docker-compose pull
docker-compose up -d
docker-compose logs -f # to see the container logs; Ctrl-C to exit
```

#### Install

* After the applying the above _deployment commands_ , open your browser on `https://<host name>.<domain name>/install.php` to proceed installation of DokuWiki through the wizard
* Fill in the form provided by the wizard and click `Save`
* As the following message appears `The configuration was finished successfully. You may delete the install.php file now. ... `, delete the install.php file:
    * `docker exec dokuwiki /bin/sh -c "rm -fr /var/www/install.php"`

#### Run

* Everything is run and ready after installation

#### Upgrade

* Use the above _deployment commands_ , it is recommended
* You can also upgrade DokuWiki automatically through its UI

## Backup

* To Do: Provide steps to backup `Traefik:/acme.json` and `DokuWiki:/data` some way
    * [gitbacked Plugin](https://www.dokuwiki.org/plugin:gitbacked)

## License

* MIT. See `LICENSE` for more details
