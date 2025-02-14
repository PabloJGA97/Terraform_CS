#!/bin/bash

# Actualizar el sistema e instalar dependencias
apt update -y
apt upgrade -y
apt install -y apache2 mysql-client php libapache2-mod-php php-mysql unzip wget

# Habilitar y arrancar Apache
systemctl enable apache2
systemctl start apache2

# Descargar y configurar WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

# Ajustar permisos y propiedad de los archivos
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Crear el archivo wp-config.php dinámicamente
cat > /var/www/html/wp-config.php <<EOL
<?php
define('DB_NAME', '${db_name}');
define('DB_USER', '${db_user}');
define('DB_PASSWORD', '${db_password}');
define('DB_HOST', '${db_host}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if (!defined('ABSPATH')) {
  define('ABSPATH', dirname(__FILE__) . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOL

# Asegurar el archivo wp-config.php
chown www-data:www-data /var/www/html/wp-config.php
chmod 640 /var/www/html/wp-config.php

# Reiniciar Apache para aplicar cambios
systemctl restart apache2

# Instalar certificados SSL (opcional)
# apt install -y certbot python3-certbot-apache
# certbot --apache -d your-domain.com --non-interactive --agree-tos -m your-email@example.com

# Habilitar firewall (opcional)
# ufw allow 'Apache Full'
# ufw enable