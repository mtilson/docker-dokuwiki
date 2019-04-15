FROM alpine:3.9

LABEL maintainer="m@tilson.biz" \
  org.label-schema.name="dokuwiki" \
  org.label-schema.description="DokuWiki" \
  org.label-schema.url="https://github.com/mtilson/dokuwiki" \
  org.label-schema.vcs-url="https://github.com/mtilson/dokuwiki" \
  org.label-schema.vendor="mtilson" \
  org.label-schema.schema-version="1.0"

RUN apk --update --no-cache add \
    inotify-tools libgd nginx supervisor tar tzdata \
    openssh-client curl git \
    php7 php7-cli php7-ctype php7-curl php7-fpm php7-gd php7-imagick php7-json php7-mbstring php7-openssl \
    php7-session php7-xml php7-simplexml php7-zip php7-zlib \
  && rm -rf /var/cache/apk/* /var/www/* /tmp/*

ENV DOKUWIKI_VERSION="2018-04-22b" \
	DOKUWIKI_MD5="605944ec47cd5f822456c54c124df255"

RUN apk update \
  && apk --update --no-cache add -t build-dependencies gnupg wget \
  && cd /tmp \
  && wget -q "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" \
  && echo "$DOKUWIKI_MD5  /tmp/dokuwiki-$DOKUWIKI_VERSION.tgz" | md5sum -c - | grep OK \
  && tar -xzf "dokuwiki-$DOKUWIKI_VERSION.tgz" --strip 1 -C /var/www \
  && apk del build-dependencies \
  && rm -rf  /root/.gnupg /tmp/* /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY assets /

RUN mkdir -p /var/log/supervisord \
  && chmod a+x /entrypoint.sh /usr/local/bin/* \
  && chown -R nginx. /var/lib/nginx /var/log/nginx /var/log/php7 /var/tmp/nginx /var/www

EXPOSE 80
WORKDIR /var/www
VOLUME [ "/data", "/root/.ssh" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
