#!/bin/bash
echo "This will enable the required modules"
sudo a2ensite nextcloud.conf 
 sudo a2enmod rewrite 
sudo a2enmod headers
 sudo a2enmod env 
 sudo a2enmod dir
 sudo a2enmod mime 
 sudo a2enmod setenvif
 sudo systemctl restart apache2
 echo "These scripts should have made a successful nextcloud installation. Continue with the web wizard. Thank you for using this Nextcloud Installer!"

