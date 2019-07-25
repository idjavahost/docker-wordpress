#!/bin/bash
set -e

if [[ ! -f /etc/.setupdone ]]; then

    # RUN INITIAL SETUP
    RANDPASS=$(date | md5sum | awk '{print $1}')
    addgroup -g 1000 $USERGROUP
    adduser -D -u 1000 -h $HOME -s /bin/bash -G $USERGROUP $USERNAME
    echo "${USERNAME}:${RANDPASS}" | chpasswd &> /dev/null
    /usr/bin/ssh-keygen -A

    if [[ ! -x "$(command -v dockerize)" ]]; then
        wget -qO - https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-alpine-linux-amd64-v0.6.1.tar.gz \
	       | tar zxf - -C /usr/local/bin
        chmod +x /usr/local/bin/dockerize
    fi

    if [[ ! -x "$(command -v wp)" ]]; then
        curl -sSo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x /usr/local/bin/wp
    fi

    if [[ ! -f /usr/local/wp-completion.bash ]]; then
        curl -sSo /usr/local/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
        chmod +x /usr/local/wp-completion.bash
    fi

    if [[ ! -f "${HOME}/wordpress/nginx.conf" ]]; then
        touch $HOME/wordpress/nginx.conf
    fi

    # PRINT WP CLI INFORMATIONS
    if [[ -x "$(wp --info)" ]]; then
        su $USERNAME -c "wp --info"
    fi

    echo "export EDITOR=nano" > $HOME/.bash_profile
    echo "source /usr/local/wp-completion.bash" >> $HOME/.bash_profile

    # SETUP SSH
    sed -ri "s/^#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    sed -ri 's/^#ListenAddress\s0+.*/ListenAddress 0\.0\.0\.0/' /etc/ssh/sshd_config
    sed -ri 's/^#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -ri 's/^#?RSAAuthentication\s+.*/RSAAuthentication yes/' /etc/ssh/sshd_config
    sed -ri 's/^#?PubkeyAuthentication\s+.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    mkdir -p $HOME/.ssh

    echo "SSH Login on Port : ${SSH_PORT}"
    if [[ -v SSH_PUBLIC_KEY ]]; then
        sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        echo "${SSH_PUBLIC_KEY}" > $HOME/.ssh/authorized_keys
        chmod 600 $HOME/.ssh/authorized_keys
        echo "SSH Authentication with Public Key enabled."
    elif [[ -v SSH_PASSWORD ]]; then
        echo "${USERNAME}:${SSH_PASSWORD}" | chpasswd &> /dev/null
        echo "SSH Authentication with password enabled."
    fi
    chmod 700 $HOME/.ssh

    # SETUP NGINX
    mkdir -p $HOME/logs
    mkdir -p /var/cache/nginx
    touch $HOME/logs/access.log
    chown -R $USERNAME:$USERGROUP /var/lib/nginx
    chown -R $USERNAME:$USERGROUP /var/tmp/nginx
    chown -R $USERNAME:$USERGROUP /var/log/nginx
    chown -R $USERNAME:$USERGROUP /var/cache/nginx
    dockerize -template /template/nginx-conf.tmpl:/etc/nginx/nginx.conf &> /dev/null

    # SETUP PHP
    mkdir -p /var/lib/php
    chown -R $USERNAME:$USERGROUP /var/lib/php
    rm /usr/local/etc/php-fpm.d/*.conf
    dockerize -template /template/php-fpm-pool.tmpl:/usr/local/etc/php-fpm.d/www.conf &> /dev/null
    dockerize -template /template/php-extra.tmpl:$PHP_INI_DIR/conf.d/00-custom.ini &> /dev/null
    dockerize -template /template/opcache.ini.tmpl:$PHP_INI_DIR/conf.d/10-opcache.ini &> /dev/null

    if [[ -f "${PHP_INI_DIR}/php.ini-production" ]]; then
        cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
    fi

    # INSTALL WORDPRESS
    mkdir -p $HOME/.wp-cli
    dockerize -template /template/wp-cli.config.tmpl:$HOME/.wp-cli/config.yml &> /dev/null
    chmod 440 $HOME/.wp-cli/config.yml

    chown -R $USERNAME:$USERGROUP $HOME

    if [[ ! -f "${HOME}/wordpress/wp-config.php" ]]; then
        if [[ ! -d "${HOME}/wordpress" ]]; then
            mkdir -p $HOME/wordpress
        fi
        echo "Downloading WordPress latest version ..."
        /usr/local/bin/php /usr/local/bin/wp --allow-root core download --path=$HOME/wordpress
        chown -R $USERNAME:$USERGROUP $HOME/wordpress
        echo "----------------------------------------------------------"
        if [[ -v DB_HOST && -v DB_NAME && -v DB_USER && -v DB_PASSWORD && -v SITE_URL && -v SITE_TITLE && -v ADMIN_USERNAME && -v ADMIN_PASSWORD && -v ADMIN_EMAIL ]]; then
            /usr/local/bin/php /usr/local/bin/wp --allow-root --path=$HOME/wordpress config create \
                --dbname=$DB_NAME \
                --dbuser=$DB_USER \
                --dbpass=$DB_PASSWORD \
                --dbhost=$DB_HOST
            /usr/local/bin/php /usr/local/bin/wp --allow-root --path=$HOME/wordpress db create
            /usr/local/bin/php /usr/local/bin/wp --allow-root --path=$HOME/wordpress core install \
                --url=$SITE_URL \
                --title=$SITE_TITLE \
                --admin_user=$ADMIN_USERNAME \
                --admin_password=$ADMIN_PASSWORD \
                --admin_email=$ADMIN_EMAIL
            echo "WordPress Installed successfully!"
            echo "Visit: ${SITE_URL}/wp-admin/"
            echo "Username: ${ADMIN_USERNAME}"
            echo "Password: ${ADMIN_PASSWORD}"
        else
            echo "WordPress not configured correctly. Please setup directly from your site!"
            echo "Visit: ${SITE_URL}/wp-admin/install.php"
        fi
        echo "----------------------------------------------------------"
    fi

    # INSTALL NODEJS YARN
    if [[ "${INSTALL_YARN}" == '1' ]]; then
        echo "Installing yarn and gulp..."
        su - $USERNAME -c "curl -o- -L https://yarnpkg.com/install.sh | bash" &> /dev/null
        echo "export PATH=\$HOME/.yarn/bin:\$HOME/.config/yarn/global/node_modules/.bin:\$PATH" >> $HOME/.bash_profile
        su - $USERNAME -c "$HOME/.yarn/bin/yarn global add gulp-cli"
    fi

    # MARK CONTAINER AS INSTALLED
    chown -R $USERNAME:$USERGROUP $HOME
    rm -rf /template
    touch /etc/.setupdone
fi

/usr/bin/supervisord -n -c /etc/supervisord.conf

exec "$@"
