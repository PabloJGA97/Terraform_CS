#!/bin/bash
sudo apt update
sudo apt install -y mysql-client
tee /tmp/crea-wordpress-db.sql <<EOF
CREATE DATABASE wordpressdb01;
CREATE USER 'asix01'@'%' IDENTIFIED BY 'Sup3rins3gura!';
GRANT ALL PRIVILEGES ON wordpressdb01.* TO 'asix01'@'%';
FLUSH PRIVILEGES;
exit
EOF

cat /tmp/crea-wordpress-db.sql | sudo mysql -u root -pPassw0rdRootAcc0unt

