#!/bin/bash
apt-get update -y
apt-get install -y apache2 php php-curl libapache2-mod-php php-mysql jq
ufw allow 'Apache Full'

usermod -a -G azureuser azureuser

mkdir -p /var/www/html
chown -R azureuser:azureuser /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
cd /var/www/html
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq > index.html
sed -i '1i<pre>' index.html
sed -i '$a</pre>' index.html
curl https://raw.githubusercontent.com/Azure/vm-scale-sets/master/terraform/terraform-tutorial/app/index.php -O