#!/bin/bash 

sudo apt update
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-client \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www
sudo tee /etc/apache2/sites-available/wordpress.conf << EOF
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo service apache2 reload
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/database_name_here/wordpressdb01/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/username_here/asix01/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/password_here/Sup3rins3gura!/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/localhost/${rds_endpoint}/' /srv/www/wordpress/wp-config.php

# creo la bbdd en un fitxero del frontend y ejecuto el output en la base de datos 

tee /tmp/crea-wordpress-db.sql <<EOF
CREATE DATABASE wordpressdb01;
CREATE USER 'asix01'@'%' IDENTIFIED BY 'Sup3rins3gura!';
GRANT ALL PRIVILEGES ON wordpressdb01.* TO 'asix01'@'%';
FLUSH PRIVILEGES;
exit
EOF

cat /tmp/crea-wordpress-db.sql | sudo mysql -u admin -pSuperSecret123 -h ${rds_endpoint}

