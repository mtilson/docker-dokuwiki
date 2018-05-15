This is forked from [crazy-max/docker-dokuwiki](https://github.com/crazy-max/docker-dokuwiki)

## About

It is [DokuWiki](https://www.dokuwiki.org/dokuwiki) Docker image. 

## Features

### Included

* Alpine Linux 3.7, Nginx, PHP 7.1
* Tarball authenticity checked during building process
* OPCache enabled to store precompiled script bytecode in shared memory
* Data, configuration, plugins and templates are stored in an unique folder

### From docker-compose

* [Traefik](https://github.com/containous/traefik-library-image) as reverse proxy and creation/renewal of Let's Encrypt certificates

## Docker

### Environment variables

* `TZ` : The timezone assigned to the container (default to `UTC`)
* `MEMORY_LIMIT` : PHP memory limit (default to `256M`)
* `UPLOAD_MAX_SIZE` : Upload max size (default to `16M`)
* `OPCACHE_MEM_SIZE` : PHP OpCache memory consumption (default to `128`)

### Volumes

* `/data` : Contains configuration, plugins, templates and data

### Ports

* `80` : HTTP port

## Use this image

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following [docker compose template](docker-compose.yml), then run the container :

```bash
touch acme.json
chmod 600 acme.json
docker-compose up -d
docker-compose logs -f
```

### Command line

You can also use the following minimal command :

```bash
$ docker run -d -p 80:80 --name dokuwiki \
  -v $(pwd)/data:/data \
  mtilson/dokuwiki:latest
```

## Upgrade

You can upgrade DokuWiki automatically through the UI, it works well. But i recommend to recreate the container whenever i push an update :

```bash
docker-compose pull
docker-compose up -d
```


## License

MIT. See `LICENSE` for more details.
