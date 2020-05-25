ARG FROM_TAG
FROM ${FROM_TAG}

ARG ALPINE_BRANCH
ARG PHPV0
ARG PHPV2

MAINTAINER Lisa Ridley "lisa@codementality.com"

LABEL BUILDDATE $(date '+%Y-%m-%d')

ADD healthcheck.sh /healthcheck.sh

RUN STARTTIME=$(date "+%s") && \
apk add --no-cache curl curl-dev fcgi mysql-client postfix && \
apk update --no-cache && apk upgrade --no-cache && \
apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community gnu-libiconv && \
apk add --no-cache --virtual gen-deps alpine-sdk autoconf binutils libbz2 libpcre16 libpcre32 \
  libpcrecpp m4 pcre-dev pcre2 pcre2-dev perl && \
PHPVER=$PHPV2 && \
PGKDIR=/home/abuild/packages && \
PKGS1="ctype|curl|dom|fpm|ftp|gd|gettext|imap|iconv|json|ldap|mbstring|mcrypt" && \
PKGS2="memcached|mysqlnd|mysqli|opcache|openssl|pdo|pdo_mysql|pdo_pgsql|pgsql" && \
PKGS3="phar|redis|simplexml|soap|sockets|tokenizer|wddx|xml|xmlreader|xmlwriter|xdebug|zip" && \
PKGS="$PKGS1|$PKGS2|$PKGS3" && \
## Beginning general installation
adduser -D abuild -G abuild -s /bin/sh && \
mkdir -p /var/cache/distfiles && \
chmod a+w /var/cache/distfiles && \
echo "abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild && \
su - abuild -c "git clone -v --depth 1 --single-branch --branch \
   $ALPINE_BRANCH https://github.com/alpinelinux/aports.git aports" && \
su - abuild -c "cd aports && git checkout $ALPINE_BRANCH" && \
su - abuild -c "cd aports && git pull" && \
su - abuild -c "cd aports/community/php$PHPV0 && abuild -r deps" && \
su - abuild -c "git config --global user.name \"Lisa Ridley\"" && \
su - abuild -c "git config --global user.email \"lisa@codementality.com\"" && \
su - abuild -c "echo ''|abuild-keygen -a -i" && \
## Use Alpine's bump command (ignore failed error)
su - abuild -c "cd aports/community/php$PHPV0 && abump -k php$PHPV0-$PHPVER || :" && \
## Beginning PHP installation
apk add --allow-untrusted $(find $PGKDIR|egrep "php$PHPV0-((common|session)-)?$PHPV0") && \
apk add --allow-untrusted --no-cache --virtual php-deps $(find $PGKDIR|egrep "php$PHPV0-(dev|phar)-$PHPV0") && \
## Build ancillary PHP packages
su - abuild -c "cd aports/community/php$PHPV0-pecl-igbinary  && abuild checksum && abuild -r"  && \
su - abuild -c "cd aports/community/php$PHPV0-pecl-mcrypt    && abuild checksum && abuild -r"  && \
su - abuild -c "cd aports/community/php$PHPV0-pecl-memcached && abuild checksum && abuild -r"  && \
su - abuild -c "cd aports/community/php$PHPV0-pecl-redis     && abuild checksum && abuild -r"  && \
su - abuild -c "cd aports/community/php$PHPV0-pecl-xdebug    && abuild checksum && abuild -r"  && \
## Installing PHP packages
apk add --allow-untrusted $(find $PGKDIR|egrep "php$PHPV0-(pecl-)?($PKGS)-.*.apk") && \
adduser -h /var/www/html -s /sbin/nologin -D -H -u 1971 php && \
chown -R postfix  /var/spool/postfix && \
chgrp -R postdrop /var/spool/postfix/public /var/spool/postfix/maildrop && \
chown -R root     /var/spool/postfix/pid && \
chown    root     /var/spool/postfix && \
echo smtputf8_enable = no >> /etc/postfix/main.cf && \
## Installing composer
cd /usr/local && \
curl -sS https://getcomposer.org/installer|php && \
/bin/mv composer.phar bin/composer && \
deluser php && \
adduser -h /var/www/html -s /bin/sh -D -H -u 1971 php && \
## Clean up and trim container
find /bin /lib /sbin /usr/bin /usr/lib /usr/sbin -type f -exec strip -v {} \; && \
apk del php-deps gen-deps && \
deluser --remove-home abuild && \
cd /usr/bin && \
rm -vrf /var/cache/apk/* /var/cache/distfiles/* mysql_waitpid mysqlimport mysqlshow mysqladmin \
    mysqlcheck mysqldump myisam_ftdump && \
## Finished
echo "Elapsed: $(expr $(date "+%s") - $STARTTIME) seconds"

USER php

ENV COLUMNS 100
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php-fpm7

HEALTHCHECK --interval=30s --timeout=60s --retries=3 CMD /healthcheck.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/sbin/php-fpm7"]

CMD ["--nodaemonize"]
