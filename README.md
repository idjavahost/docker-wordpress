# WordPress :heart: Docker

Simple implementation WordPress on docker container.

### Features
- Nginx proxy with FastCGI Cache
- PHP 7.3 with fpm
- Redis & memcaced optimized
- Customizeable php configuration
- WP CLI ready to use
- Optional install Yarn

### Environment Variables
- `VIRTUAL_HOST` (:wordpress.localhost) : name your nginx virtual host, support multiple host separated by space
- `USERNAME` (:wordpress) : linux username for running WordPress & SSH login
- `USERGROUP` (:wordpress) : linux user group for running WordPress & SSH login
- `HTTPS` (:off) : tell php if WordPress inside https proxy
- `HOME` (:/var/www) : user home, WordPress root will added here inside `wordpress` directory
- `SSH_PORT` (:2222) : SSH port
- `SSH_PUBLIC_KEY` (:'') : Use public key authentication and disable password clear text login
- `SSH_PASSWORD` (:'') : SSH password optional if you prefered using SSH public key
- `TZ` (:Asia/Jakarta) : Your [PHP Timezone](http://php.net/manual/en/timezones.php)
- `PHP_MEMORY_LIMIT` (:128M) : PHP memory limit
- `PHP_UPLOAD_MAX_SIZE` (:50M) : PHP maximum file size on upload
- `PHP_SESSION_SAVE_HANDLER` (:files) : Session handler, you can use redis or memcached here
- `PHP_SESSION_SAVE_PATH` (:/var/lib/php/sessions) : Session save path location, for redis or memcaced use tcp or sock path
- `FPM_MAX_CHILDREN` (:5) : php-fpm pm.max_children per request
- `FPM_START_SERVER` (:2) : php-fpm initial child process
- `FPM_MAX_SPARE_SERVERS` (:3) : php-fpm maximum spare server process
- `FPM_ERROR_LOG` (:/dev/fd/2) : PHP error log, default output to docker logger
- `OPCACHE_ENABLE` (:1) : 1 or 0 to disable php opcache code
- `OPCACHE_ENABLE_CLI` (:0) : enable opcache on php cli
- `OPCACHE_MEMORY` (:128) : number only, max opcache memory limit
- `NGINX_ACCESS_LOG` (:/var/log/nginx/access.log main) : `off` to disable nginx access log
- `INSTALL_YARN` (:0) : Choose to install yarn package manager or not

If this WordPress need a clean install or mapped volume not configured to `/var/www/wordpress`. You nedd to specify all WordPress installation information here. All Environment below is required for first run this container.

- `DB_HOST` : localhost or server IP
- `DB_NAME` : database name, if not exists wp-cli will try to create this
- `DB_USER` : database user privileges
- `DB_PASSWORD` : databse user password
- `SITE_URL` : WordPress site URL
- `SITE_TITLE` : WordPress site name
- `ADMIN_USERNAME` : WordPress administrator user
- `ADMIN_PASSWORD` : WordPress administrator password
- `ADMIN_EMAIL` : WordPress administrator email address
