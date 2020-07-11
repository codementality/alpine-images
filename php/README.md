## Alpine based PHP images

[![Build Status](https://travis-ci.com/codementality/alpine-images.svg?branch=master)](https://travis-ci.com/codementality/alpine-images)

* PHP 7.2
* PHP 7.3
* PHP 7.4

The following PHP modules are included in these builds:

* ctype
* curl
* date
* dom
* filter
* ftp
* gd
* gettext
* hash
* iconv
* igbinary
* imap
* json
* ldap
* libxml
* mbstring
* mcrypt
* memcached
* mysqli
* mysqlnd
* openssl
* pcre
* PDO
* pdo_mysql
* pdo_pgsql
* pgsql
* Phar
* readline
* redis
* session
* SimpleXML
* soap
* sockets
* SPL
* tokenizer
* wddx
* xml
* xmlreader
* xmlwriter
* Zend OPcache
* zip
* zlib

In addition, Composer is also installed, as is the Drush Launcher.  Make sure you include drush as part of your project.

To use, you will need to mount some configuration files into the container.

* Error logs:         volume mount to /var/log/php7
* PHP Configuration:  volume mount to /etc/php7
* Application:        volume mount to /var/www/html
