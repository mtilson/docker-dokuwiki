#!/bin/sh

function runas_nginx() {
  su - nginx -s /bin/sh -c "$1"
}

TZ=${TZ:-"UTC"}
MEMORY_LIMIT=${MEMORY_LIMIT:-"256M"}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-"16M"}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-"128"}

# Timezone
echo "[entrypoint.sh] Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "[entrypoint.sh] Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

# OpCache
echo "[entrypoint.sh] Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php7/conf.d/opcache.ini > /etc/php7/conf.d/opcache.ini

# Nginx
echo "[entrypoint.sh] Setting Nginx configuration..."
sed -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

# DokuWiki
echo "[entrypoint.sh] Initializing DokuWiki files / folders..."
mkdir -p /data/plugins /data/tpl

echo "[entrypoint.sh] Adding preload.php..."
cp -f /tpls/preload.php /var/www/inc/
chown nginx. /var/www/inc/preload.php

echo "[entrypoint.sh] Copying global config..."
cp -Rf /var/www/conf /data/
chown -R nginx. /data/conf

echo "[entrypoint.sh] Mogifying install.php..."
test -f /var/www/install.php &&
  sed -i "1s/.*/<?php define('DOKU_CONF', '\/data\/conf\/'); define('DOKU_LOCAL', '\/data\/conf\/');/" /var/www/install.php

firstInstall=0
if [ ! -f /data/conf/local.protected.php ]; then
  firstInstall=1
  echo "[entrypoint.sh] First install detected..."
fi

if [ ! -d /data/data ]; then
  echo "[entrypoint.sh] Creating initial data folder..."
  cp -Rf /var/www/data /data/
  chown -R nginx. /data/data
fi

echo "[entrypoint.sh] Bootstrapping configuration..."
cat > /data/conf/local.protected.php <<EOL
<?php

\$conf['savedir'] = '/data/data';
EOL
chown nginx. /data/conf/local.protected.php

echo -n "[entrypoint.sh] Saving bundled plugins list..."
bundledPlugins=$(ls -d /var/www/lib/plugins/*/ | cut -f6 -d'/')
for bundledPlugin in ${bundledPlugins}; do
  echo "${bundledPlugin}" >> /tmp/bundledPlugins.txt
done
echo " $(wc -l < /tmp/bundledPlugins.txt) found"

echo -n "[entrypoint.sh] Saving bundled templates list..."
bundledTpls=$(ls -d /var/www/lib/tpl/*/ | cut -f6 -d'/')
for bundledTpl in ${bundledTpls}; do
  echo "${bundledTpl}" >> /tmp/bundledTpls.txt
done
echo " $(wc -l < /tmp/bundledTpls.txt) found"

echo "[entrypoint.sh] Checking user plugins in /data/plugins..."
userPlugins=$(ls -l /data/plugins | egrep '^d' | awk '{print $9}')
for userPlugin in ${userPlugins}; do
  if [ -d /var/www/lib/plugins/${userPlugin} ]; then
    echo "[entrypoint.sh] WARNING: Plugin ${userPlugin} will not be used (already bundled in DokuWiki)"
    continue
  fi
  ln -sf /data/plugins/${userPlugin} /var/www/lib/plugins/${userPlugin}
  chown -h nginx. /var/www/lib/plugins/${userPlugin}
done

echo "[entrypoint.sh] Checking user templates in /data/tpl..."
userTpls=$(ls -l /data/tpl | egrep '^d' | awk '{print $9}')
for userTpl in ${userTpls}; do
  if [ -d /var/www/lib/tpl/${userTpl} ]; then
    echo "[entrypoint.sh] WARNING: Template ${userTpl} will not be used (already bundled in DokuWiki)"
    continue
  fi
  ln -sf /data/tpl/${userTpl} /var/www/lib/tpl/${userTpl}
  chown -h nginx. /var/www/lib/tpl/${userTpl}
done

# Fix perms
echo "[entrypoint.sh] Fixing permissions..."
chown -R nginx. /data

# First install ?
if [ ${firstInstall} -eq 1 ]; then
  echo "[entrypoint.sh]"
  echo ">>"
  echo ">> Point your browser to DokuWiki installation wizard (/install.php) to proceed with installation."
  echo ">>"
else
  if [ -f /data/conf/local.php -o -f /data/conf/users.auth.php -o -f /data/conf/acl.auth.php ]; then
    echo "[entrypoint.sh] Removing install.php..."
    rm -fr /var/www/install.php

    echo "[entrypoint.sh] Launching DokuWiki indexer..."
    runas_nginx 'php7 /var/www/bin/indexer.php -c'
  else
    echo "[entrypoint.sh]"
    echo ">>"
    echo ">> This is not the first time this continer run."
    echo ">> But it seems you didn't go through DokuWiki installation wizard (/install.php)."
    echo ">> Please do it now to finish your installation procedure."
    echo ">> Point your browser to /install.php"
    echo ">>"
  fi
fi

exec "$@"
