#!/bin/sh

test -n "$DW_BACKUP_GIT_REMOTE_URL" || 
    { echo "$0: error: variable DW_BACKUP_GIT_REMOTE_URL is not defined, exiting" ; exit 255 ; }

DW_BACKUP_GIT_SERVER_NAME=$(echo $DW_BACKUP_GIT_REMOTE_URL | cut -d"@" -f2 | cut -d":" -f1)
test -n "$DW_BACKUP_GIT_SERVER_NAME" ||
    { echo "$0: error: invalid git remote url ($DW_BACKUP_GIT_REMOTE_URL), exiting" ; exit 255 ; }

DW_DOMAIN=${DW_DOMAIN:-"example.com"}

TZ=${TZ:-"UTC"}
MEMORY_LIMIT=${MEMORY_LIMIT:-"256M"}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-"16M"}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-"128"}

function runas_nginx() {
  su - nginx -s /bin/sh -c "$1"
}

function plugins_and_templates() {
  echo -n "$0: log: bundled plugins saved: /tmp/bundledPlugins.txt, "
  bundledPlugins=$(ls -d /var/www/lib/plugins/*/ | cut -f6 -d'/')
  > /tmp/bundledPlugins.txt
  for bundledPlugin in ${bundledPlugins}; do
    echo "${bundledPlugin}" >> /tmp/bundledPlugins.txt
  done
  echo "$0: log: $(wc -l < /tmp/bundledPlugins.txt) found"

  echo -n "$0: log: bundled templates saved: /tmp/bundledTpls.txt, "
  bundledTpls=$(ls -d /var/www/lib/tpl/*/ | cut -f6 -d'/')
  > /tmp/bundledTpls.txt
  for bundledTpl in ${bundledTpls}; do
    echo "${bundledTpl}" >> /tmp/bundledTpls.txt
  done
  echo "$0: log: $(wc -l < /tmp/bundledTpls.txt) found"

  userPlugins=$(ls -l /data/plugins | egrep '^d' | awk '{print $9}')
  for userPlugin in ${userPlugins}; do
    if [ -d /var/www/lib/plugins/${userPlugin} ]; then
      echo "$0: log: WARNING: Plugin ${userPlugin} will not be used (already bundled in DokuWiki)"
      continue
    fi
    echo "$0: log: link: /var/www/lib/plugins/${userPlugin} -> /data/plugins/${userPlugin}"
    ln -sf /data/plugins/${userPlugin} /var/www/lib/plugins/${userPlugin}
    chown -h nginx: /var/www/lib/plugins/${userPlugin}
  done

  userTpls=$(ls -l /data/tpl | egrep '^d' | awk '{print $9}')
  for userTpl in ${userTpls}; do
    if [ -d /var/www/lib/tpl/${userTpl} ]; then
      echo "$0: log: WARNING: Template ${userTpl} will not be used (already bundled in DokuWiki)"
      continue
    fi
    echo "$0: log: link: /var/www/lib/tpl/${userTpl} -> /data/tpl/${userTpl}"
    ln -sf /data/tpl/${userTpl} /var/www/lib/tpl/${userTpl}
    chown -h nginx: /var/www/lib/tpl/${userTpl}
  done
}

echo "$0: log: timezone: ${TZ}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "$0: log: php-fpm config file: /etc/php7/php-fpm.d/www.conf"
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

# OpCache
echo "$0: log: opcache config file: /etc/php7/conf.d/opcache.ini"
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php7/conf.d/opcache.ini > /etc/php7/conf.d/opcache.ini

# Nginx
echo "$0: log: nginx config file: /etc/nginx/nginx.conf"
sed -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

echo "$0: log: php preload file: /var/www/inc/preload.php"
cp -f /tpls/preload.php /var/www/inc/
chown nginx: /var/www/inc/preload.php

echo "$0: log: php install file: /var/www/install.php"
install_php_present=0
test -f /var/www/install.php &&
  { sed -i "1s/.*/<?php define('DOKU_CONF', '\/data\/conf\/'); define('DOKU_LOCAL', '\/data\/conf\/');/" /var/www/install.php; 
    install_php_present=1;
  }

git config --global user.email "dokuwiki-backup@${DW_DOMAIN}"
git config --global user.name "dokuwiki-backup"

cat >> ~/.profile << EOF
alias ll='ls -la'
EOF

message=""
delay=0

test -d ~/.ssh || { mkdir -p ~/.ssh; chmod 700 ~/.ssh; }

test -f ~/.ssh/config || {
  cat > ~/.ssh/config << EOF
Host $DW_BACKUP_GIT_SERVER_NAME
    StrictHostKeyChecking no
EOF
  chmod 400 ~/.ssh/config
  }

test -f ~/.ssh/id_rsa || {
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -C "dokuwiki-backup@${DW_DOMAIN}";
  delay=120
  message="Sleeping for $delay seconds to add the above key to git server account"
  }

test -f ~/.ssh/id_rsa.pub || { echo "$0: error: no ~/.ssh/id_rsa.pub file, exiting"; exit 255; }

echo "Public key for $DW_BACKUP_GIT_SERVER_NAME git server for backup:"
cat ~/.ssh/id_rsa.pub

test $delay -eq 0 || {
    echo "Sleeping for $delay seconds to add the above key to git server account $message"
    sleep $delay
    }

data_commited=0
if [ ! -d /data/.git ]; then
    echo "$0: log: clone $DW_BACKUP_GIT_REMOTE_URL to /data"
    rm -fr /data/*
    git clone $DW_BACKUP_GIT_REMOTE_URL /data

    test -d /data/.git/objects || { echo "$0: error: no /data/.git/objects after cloning repo, exiting"; exit 255; }
    object_count=$(find /data/.git/objects -type f | wc -l)

    test -n "$object_count" || { echo "$0: error: number of objects is empty, exiting"; exit 255; }
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

        echo "$0: log: commit /data to $DW_BACKUP_GIT_REMOTE_URL" 
        cd /data
        git add -A
        git commit -m "wiki created @ `date -u`"
        git push -u origin master

        data_commited=1
    else
        echo "$0: log: cloned $DW_BACKUP_GIT_REMOTE_URL to /data"

        test -d /data/data/cache || mkdir /data/data/cache
        test -d /data/data/index || mkdir /data/data/index
        test -d /data/data/locks || mkdir /data/data/locks
        test -d /data/data/tmp || mkdir /data/data/tmp

        chown -R nginx: /data
    fi
else
    echo "$0: log: pull $DW_BACKUP_GIT_REMOTE_URL to /data"
    cd /data
    git pull origin master
    chown -R nginx: /data
fi

if [ $install_php_present -eq "1" -a $data_commited -eq "0" ]; then
  echo "$0: log: /var/www/install.php present and /data was not committed on this run"
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
  echo "$0: log: launching '/var/www/bin/indexer.php -c'"
  runas_nginx 'php7 /var/www/bin/indexer.php -c'
else
  echo ">>"
  echo ">> Point your browser to DokuWiki installation wizard (/install.php) to finish installation."
  echo ">>"
fi

exec "$@"
