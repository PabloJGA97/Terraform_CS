#!/bin/bash 

# instala apache, php, extensiones de php y el cliente de mysql
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
# crea una carpeta en /srv/www ya que este será el nuevo root directory y no el /var/www/ que es que viene por defecto
sudo mkdir -p /srv/www
# asigna como propietario y grupo a www-data, el usuario de Apache
sudo chown www-data: /srv/www
# descarga los directorios comprimidos de wordpress y los descomprime como el usuario www-data en dentro de la carpeta /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

# en wordpress.conf, que vendria a saber el configurable de un servidor web en sites-available, asigna el DocumentRoot como del servidor
# como /srv/www/wordpress y define dos directorios, el wordpress/ y el subdirectorio /wordpress/wp-content
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
# habilita el configurador wordpress.conf en sites-enabled
sudo a2ensite wordpress
# habilita el modulo redirigir 
sudo a2enmod rewrite
# deshabilita el modulo por defecto
sudo a2dissite 000-default
# reinicia el servicio de apache para aplicar los cambios en la configuracion
sudo service apache2 reload
# como usuario www-data copia el contenido del fichero config-sample.php en wp-config.php
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php

# sustitutuye cada linea pasada por parámetro en el directorio destino wp-config.php
sudo -u www-data sed -i 's/database_name_here/wordpressdb01/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/username_here/asix01/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/password_here/Sup3rins3gura!/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/localhost/${rds_endpoint}/' /srv/www/wordpress/wp-config.php

# creo un archivo .sql con los comandos para crear la base de datos, un usuario con su contraseña y todos los permisos de wordpressdb01 
tee /tmp/crea-wordpress-db.sql <<EOF
CREATE DATABASE wordpressdb01;
CREATE USER 'asix01'@'%' IDENTIFIED BY 'Sup3rins3gura!';
GRANT ALL PRIVILEGES ON wordpressdb01.* TO 'asix01'@'%';
FLUSH PRIVILEGES;
exit
EOF

# imprime el contenido del archivo con las comandos que hemos creados y redirige el output como input de una conexion a la base de datos
cat /tmp/crea-wordpress-db.sql | sudo mysql -u admin -pSuperSecret123 -h ${rds_endpoint}

# sudo mysql -u admin -pSuperSecret123 -h my-rds.cusmw3ofs01b.us-east-1.rds.amazonaws.com

