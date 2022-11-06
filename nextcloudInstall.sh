#!/bin/bash

echo "THIS IS A NEXTCLOUD INSTALL SCRIPT
only meant for debian based systems. Uses apache and 
postgreSQL. This script is meant to be used with
reverse proxy using NGINX."

if [ $USER != "root" ]; then
   echo "You MUST be root, not $USER "
   exit
else
   echo "You are root, we will continue with installation" 
fi

echo "Now upgrading your system and installing all required packages"

sudo apt update && sudo apt upgrade -y
sudo apt install apache2 libapache2-mod-php8.1 php8.1 php8.1-fpm php8.1-common php8.1-pgsql php8.1-cli php8.1-gd php8.1-curl php8.1-zip php8.1-xml php8.1-mbstring php8.1-bz2 php8.1-intl php8.1-bcmath php8.1-gmp php-imagick php8.1-opcache php8.1-readline postgresql postgresql-contrib unzip -y

ncver=$(wget -nv https://www.nextcloud.com/changelog/#latest24 && cat index.html | grep "Version 24." | head -n1 | sed 's/<\/*[^>]*>//g' | awk '{print $2}')
echo "Downloading Nextcloud $ncver"
rm -f index.html
echo "Now downloading the Nexctcloud package and the checksum file"
wget https://download.nextcloud.com/server/releases/nextcloud-${ncver}.zip
wget https://download.nextcloud.com/server/releases/nextcloud-${ncver}.zip.sha256 
echo "Checking SHA256 sum of the 2 files"
sha256sum -c nextcloud-${ncver}.zip.sha256 < nextcloud-${ncver}.zip
echo "now unzipping the package"
unzip -q nextcloud-${ncver}.zip
echo "What is the directory you want to install Nextcloud into?"
read  installdir  
echo $installdir "is your chosen directory"

[ -d $installdir ] && echo $installdir "exists"
[ ! -d $installdir ] && echo $installdir "does not exist" && exit
sudo cp -r nextcloud $installdir
echo "Just copied the nextcloud files to the install directory at $installdir"
echo "Now we will set up the database."
echo "What is your desired database username"
read dataUser
echo "What is your desired password for the Database?"
read -s dataPass
echo "Default database name is nextcloud. Continuing....."
dbname=nextcloud
sudo -u postgres psql -U postgres -c "CREATE USER $dataUser WITH PASSWORD '$dataPass';" 
sudo -u postgres psql -U postgres -c "CREATE DATABASE $dbname TEMPLATE template0 ENCODING 'UNICODE';"
sudo -u postgres psql -U postgres -c "ALTER DATABASE $dbname OWNER TO $dataUser;"
sudo -u postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $dataUser;"
echo Database setup complete 
echo In order for this to work, you MUST copy your old config one or make a new config file at /etc/apache2/sites-enabled/nextcloud.conf. For more help, please reference Nextcloud documentation
echo "Name the file nextcloud.conf and put into the directory /etc/apache2/sites-enabled/ then you must run sudo bash postInstall.sh"
