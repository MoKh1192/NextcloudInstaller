#!/bin/bash

echo "THIS IS A NEXTCLOUD INSTALL SCRIPT
only meant for debian based systems. Uses apache and 
postgreSQL."

if [ $EUID != "0" ]; then
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
read installdir  
echo $installdir "is your chosen directory"
[ -d $installdir ] && echo $installdir "exists"
[ ! -d $installdir ] && echo $installdir "does not exist. Creating it" && mkdir $installdir
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
echo "Will you be using a reverse proxy in front of this machine? (y/n)"
read rproxyExists
 while [[ "$rproxyExists" != "y" ]] && [[ "$rpoxyExists" != "n" ]];
  do
    echo "Invalid input. Re enter y or n"
    read rproxyExists
  done

if [[ "$rproxyExists" == "y" ]]; then
  echo "We will continue assuming you have your reverse proxy all set up with SSL."
  sed -i -e "s|installdir|${installdir}|g" nextcloud.conf
  echo "Enter the full domain name that will server nextcloud"
  read domain
  sed -i -e "s|domain.tld|$domain|g" nextcloud.conf
  sudo cp nextcloud.conf /etc/apache2/sites-available/
  sudo a2ensite nextcloud.conf
  echo "Enabling required Apache modules"
  sudo a2enmod rewrite 
  sudo a2enmod headers
  sudo a2enmod env 
  sudo a2enmod dir
  sudo a2enmod mime 
  sudo a2enmod setenvif
  sudo a2dissite 000-default.conf 
  sudo systemctl restart apache2

fi
if [[ "$rproxyExists" == "n" ]]; then
    echo "We will continue as if this will be the priimary machine, with no reverse proxy. This means this server will be set up with SSL certificates provided by Certbot"
    sed -i -e "s|installdir|${installdir}|g" nextcloud.conf
    echo "Enter the full domain name that will server nextcloud"
    read domain
    sed -i -e "s|domain.tld|$domain|g" nextcloud.conf
    sudo cp nextcloud.conf /etc/apache2/sites-available/
    sudo a2ensite nextcloud.conf
    echo "Enabling required Apache modules"
    sudo a2enmod rewrite 
    sudo a2enmod headers
    sudo a2enmod env 
    sudo a2enmod dir
    sudo a2enmod mime 
    sudo a2enmod setenvif
    sudo a2enmod ssl
    sudo systemctl restart apache2
    sudo a2ensite default-ssl
    sudo apt install snapd
    sudo snap install core
    sudo snap refresh core
    sudo snap install certbot --classic
    echo "Now requesting SSL certificates for Nextcloud from Let's Encrypt. You must have ports open on the firewall level and you must have DNS configured for this to work."
    sudo certbot --apache
fi 
sudo chown -R www-data:www-data ${installdir}
echo "This has completed a large portion of the installation process for Nextcloud. Go the URL you have designated for nextcloud and complete the wizard. If you have any issues, or would like to to do more tuning and security enhacements (highly recommended), please visit the admin manual at https://docs.nextcloud.com/server/latest/admin_manual/installation/index.html  Thanks for using this script!"

