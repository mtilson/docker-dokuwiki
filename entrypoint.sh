#!/bin/sh

test -n "$GIT_REMOTE_URL" || { echo "[entrypoint.sh] error: GIT_REMOTE_URL is empty"; exit 255; }
test -n "$GIT_SERVER_NAME" || { echo "[entrypoint.sh] error: GIT_SERVER_NAME is empty"; exit 255; }

DWHOST=${DWHOST:-"dokuwiki"}
DWDOMAIN=${DWDOMAIN:-"example.com"}
TZ=${TZ:-"UTC"}
MEMORY_LIMIT=${MEMORY_LIMIT:-"256M"}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-"16M"}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-"128"}

function runas_nginx() {
  su - nginx -s /bin/sh -c "$1"
}

function plugins_and_templates() {
  echo -n "[entrypoint.sh] bundled plugins saved: /tmp/bundledPlugins.txt, "
  bundledPlugins=$(ls -d /var/www/lib/plugins/*/ | cut -f6 -d'/')
  > /tmp/bundledPlugins.txt
  for bundledPlugin in ${bundledPlugins}; do
    echo "${bundledPlugin}" >> /tmp/bundledPlugins.txt
  done
  echo " $(wc -l < /tmp/bundledPlugins.txt) found"

  echo -n "[entrypoint.sh] bundled templates saved: /tmp/bundledTpls.txt, "
  bundledTpls=$(ls -d /var/www/lib/tpl/*/ | cut -f6 -d'/')
  > /tmp/bundledTpls.txt
  for bundledTpl in ${bundledTpls}; do
    echo "${bundledTpl}" >> /tmp/bundledTpls.txt
  done
  echo " $(wc -l < /tmp/bundledTpls.txt) found"

  userPlugins=$(ls -l /data/plugins | egrep '^d' | awk '{print $9}')
  for userPlugin in ${userPlugins}; do
    if [ -d /var/www/lib/plugins/${userPlugin} ]; then
      echo "[entrypoint.sh] WARNING: Plugin ${userPlugin} will not be used (already bundled in DokuWiki)"
      continue
    fi
    echo "[entrypoint.sh] link: /var/www/lib/plugins/${userPlugin} -> /data/plugins/${userPlugin}"
    ln -sf /data/plugins/${userPlugin} /var/www/lib/plugins/${userPlugin}
    chown -h nginx: /var/www/lib/plugins/${userPlugin}
  done

  userTpls=$(ls -l /data/tpl | egrep '^d' | awk '{print $9}')
  for userTpl in ${userTpls}; do
    if [ -d /var/www/lib/tpl/${userTpl} ]; then
      echo "[entrypoint.sh] WARNING: Template ${userTpl} will not be used (already bundled in DokuWiki)"
      continue
    fi
    echo "[entrypoint.sh] link: /var/www/lib/tpl/${userTpl} -> /data/tpl/${userTpl}"
    ln -sf /data/tpl/${userTpl} /var/www/lib/tpl/${userTpl}
    chown -h nginx: /var/www/lib/tpl/${userTpl}
  done
}

echo "[entrypoint.sh] timezone: ${TZ}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "[entrypoint.sh] php-fpm config file: /etc/php7/php-fpm.d/www.conf"
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

# OpCache
echo "[entrypoint.sh] opcache config file: /etc/php7/conf.d/opcache.ini"
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php7/conf.d/opcache.ini > /etc/php7/conf.d/opcache.ini

# Nginx
echo "[entrypoint.sh] nginx config file: /etc/nginx/nginx.conf"
sed -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

echo "[entrypoint.sh] php preload file: /var/www/inc/preload.php"
cp -f /tpls/preload.php /var/www/inc/
chown nginx: /var/www/inc/preload.php

echo "[entrypoint.sh] php install file: /var/www/install.php"
install_php_present=0
test -f /var/www/install.php &&
  { sed -i "1s/.*/<?php define('DOKU_CONF', '\/data\/conf\/'); define('DOKU_LOCAL', '\/data\/conf\/');/" /var/www/install.php; 
    install_php_present=1;
  }

cat >> ~/.profile << EOF
alias ll='ls -la'
EOF

message=", (it was not changes this run)"
test -d ~/.ssh || { mkdir -p ~/.ssh; chmod 700 ~/.ssh; }
test -f ~/.ssh/id_rsa || {
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -C "${DWHOST}@${DWDOMAIN}";
  message=", (it was newly generated this run)"
  }

> ~/.ssh/known_hosts
while true
do
    if [ -s ~/.ssh/known_hosts ]; then
        break
    else
        ssh-keyscan $GIT_SERVER_NAME > ~/.ssh/known_hosts
        sleep 1
    fi
done

git config --global user.email "${DWHOST}@${DWDOMAIN}"
git config --global user.name "${DWHOST}"

test -f ~/.ssh/id_rsa.pub || { echo "[entrypoint.sh] error: no ~/.ssh/id_rsa.pub file"; exit 255; }

echo "[entrypoint.sh] $GIT_SERVER_NAME git server public key:"
cat ~/.ssh/id_rsa.pub

delay=60
echo "[entrypoint.sh] sleeping for $delay seconds to add the above key to git server account $message"
sleep $delay

data_commited=0
if [ ! -d /data/.git ]; then
    echo "[entrypoint.sh] clone $GIT_REMOTE_URL to /data"
    rm -fr /data/*
    git clone $GIT_REMOTE_URL /data

    test -d /data/.git/objects || { echo "[entrypoint.sh] error: no /data/.git/objects after cloning repo"; exit 255; }
    object_count=$(find /data/.git/objects -type f | wc -l)

    test -n "$object_count" || { echo "[entrypoint.sh] error: number of objects is empty"; exit 255; }
    if [ "$object_count" -eq "0" ]; then

        mkdir -p /data/plugins /data/tpl
        touch /data/plugins/.dummy
        touch /data/tpl/.dummy
        cp -Rf /var/www/conf /data/
        cp -Rf /var/www/data /data/
        cp -f /tpls/local.protected.php /data/conf
        cp -f /tpls/.gitignore /data/

        plugins_and_templates

        chown -R nginx: /data

        echo "[entrypoint.sh] commit /data to $GIT_REMOTE_URL" 
        cd /data
        git add -A
        git commit -m "wiki created @ `date -u`"
        git push -u origin master

        data_commited=1
    else
        echo "[entrypoint.sh] cloned $GIT_REMOTE_URL to /data"

        test -d /data/data/cache || mkdir /data/data/cache
        test -d /data/data/index || mkdir /data/data/index
        test -d /data/data/locks || mkdir /data/data/locks
        test -d /data/data/tmp || mkdir /data/data/tmp

        chown -R nginx: /data
    fi
else
    echo "[entrypoint.sh] pull $GIT_REMOTE_URL to /data"
    cd /data
    git pull origin master
    chown -R nginx: /data
fi

if [ $install_php_present -eq "1" -a $data_commited -eq "0" ]; then
  echo "[entrypoint.sh] /var/www/install.php present and /data was not committed on this run"
  cp -Rf /var/www/conf /data/
  plugins_and_templates
  chown -R nginx: /data

  cd /data
  git add -A
  git commit -m "wiki updated @ `date -u`"
  git push -u origin master
fi

if [ -f /data/conf/local.php -o -f /data/conf/users.auth.php -o -f /data/conf/acl.auth.php ]; then
  rm -fr /var/www/install.php
  echo "[entrypoint.sh] launching '/var/www/bin/indexer.php -c'"
  runas_nginx 'php7 /var/www/bin/indexer.php -c'
else
  echo "[entrypoint.sh]"
  echo ">>"
  echo ">> Point your browser to DokuWiki installation wizard (/install.php) to finish installation."
  echo ">>"
fi

exec "$@"
