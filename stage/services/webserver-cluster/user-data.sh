#!/bin/bash
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>Hello, Welcome To My Terraform Provisioned Webpage!</h1><br /><p>Database: ${db_address}</p><br /><p>Port: ${db_port}</p></html>" > index.html