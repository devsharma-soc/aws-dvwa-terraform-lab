#!/bin/bash
# Log all output to a file for debugging
exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting DVWA setup..."

# 1. Update system and install dependencies
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y apache2 php libapache2-mod-php php-mysql mysql-server git php-gd curl

echo "LAMP stack and Git installed."

# 2. Configure MySQL for security and DVWA
echo "Configuring MySQL security and DVWA database..."

# Give MySQL a moment to start up fully before trying to connect
sleep 10

# Execute MySQL hardening steps non-interactively using SQL commands
# We're connecting as 'root' using auth_socket (sudo mysql -u root)
# The DVWA user password will still be set securely.
DVWA_DB_PASSWORD="y6t3K[CHErw(E>=k" # **CHANGE THIS TO A REAL, STRONG PASSWORD!**

sudo mysql -u root <<MYSQL_SCRIPT_HARDENING
# Equivalent of VALIDATE PASSWORD COMPONENT?: y
# Ensure the component is loaded and set a policy.
# This assumes the validate_password component is installed by default (common in MySQL 8+).
INSTALL COMPONENT 'file://component_validate_password';
SET GLOBAL validate_password.policy = MEDIUM; # Or STRONG, but MEDIUM is fine for lab
SET GLOBAL validate_password.length = 8; # Minimum length

# Equivalent of Remove anonymous users?: y
DELETE FROM mysql.user WHERE User='';

# Equivalent of Disallow root login remotely?: y
# By default, 'root'@'localhost' is fine with auth_socket.
# This removes any root users that might exist with '%' (remote access).
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

# Equivalent of Remove test database and access to it?: y
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; # Removes users with access to test database

# Create DVWA database and user
CREATE DATABASE dvwa;
CREATE USER 'dvwauser'@'localhost' IDENTIFIED BY '${DVWA_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwauser'@'localhost';

# Equivalent of Reload privilege tables now?: y
FLUSH PRIVILEGES;
MYSQL_SCRIPT_HARDENING

echo "MySQL database and user created for DVWA, and security hardening applied (without root password)."

# 3. Deploy DVWA Files
sudo git clone https://github.com/digininja/DVWA.git /var/www/html/dvwa
echo "DVWA cloned."

# 4. Configure DVWA config file
# Instead of copying and sed-ing, we'll generate the file directly.
sudo tee /var/www/html/dvwa/config/config.inc.php > /dev/null <<EOF
<?php

# If you are having problems connecting to the MySQL database and all of the variables below are correct
# try changing the 'db_server' variable from localhost to 127.0.0.1. Fixes a problem due to sockets.
#    Thanks to @digininja for the fix.

# Database management system to use
\$DBMS = getenv('DBMS') ?: 'MySQL';
#\$DBMS = 'PGSQL'; // Currently disabled

# Database variables
#    WARNING: The database specified under db_database WILL BE ENTIRELY DELETED during setup.
#    Please use a database dedicated to DVWA.
#
# If you are using MariaDB then you cannot use root, you must use create a dedicated DVWA user.
#    See README.md for more information on this.
\$_DVWA = array();
\$_DVWA[ 'db_server' ]   = '127.0.0.1'; # Keep 127.0.0.1 for consistency with DVWA's default. If you prefer 'localhost', change here.
\$_DVWA[ 'db_database' ] = 'dvwa';
\$_DVWA[ 'db_user' ]     = 'dvwauser'; # <<< Directly set to dvwauser
\$_DVWA[ 'db_password' ] = '${DVWA_DB_PASSWORD}'; # <<< Directly set with your variable
\$_DVWA[ 'db_port']      = '3306';

# ReCAPTCHA settings
#    Used for the 'Insecure CAPTCHA' module
#    You'll need to generate your own keys at: https://www.google.com/recaptcha/admin
\$_DVWA[ 'recaptcha_public_key' ]  = getenv('RECAPTCHA_PUBLIC_KEY') ?: '';
\$_DVWA[ 'recaptcha_private_key' ] = getenv('RECAPTCHA_PRIVATE_KEY') ?: '';

# Default security level
#    Default value for the security level with each session.
#    The default is 'impossible'. You may wish to set this to either 'low', 'medium', 'high' or impossible'.
\$_DVWA[ 'default_security_level' ] = getenv('DEFAULT_SECURITY_LEVEL') ?: 'impossible';

# Default locale
#    Default locale for the help page shown with each session.
#    The default is 'en'. You may wish to set this to either 'en' or 'zh'.
\$_DVWA[ 'default_locale' ] = getenv('DEFAULT_LOCALE') ?: 'en';

# Disable authentication
#    Some tools don't like working with authentication and passing cookies around
#    so this setting lets you turn off authentication.
\$_DVWA[ 'disable_authentication' ] = getenv('DISABLE_AUTHENTICATION') ?: false;

define ('MYSQL', 'mysql');
define ('SQLITE', 'sqlite');

# SQLi DB Backend
#    Use this to switch the backend database used in the SQLi and Blind SQLi labs.
#    This does not affect the backend for any other services, just these two labs.
#    If you do not understand what this means, do not change it.
\$_DVWA['SQLI_DB'] = getenv('SQLI_DB') ?: MYSQL;
#\$_DVWA['SQLI_DB'] = SQLITE;
#\$_DVWA['SQLITE_DB'] = 'sqli.db';

?>
EOF
echo "DVWA configuration file generated directly."

# 5. Set Permissions for DVWA
sudo chown -R www-data:www-data /var/www/html/dvwa
sudo chmod -R 775 /var/www/html/dvwa/
sudo chmod 777 /var/www/html/dvwa/hackable/uploads/ # Required by DVWA for upload functionality
sudo chmod 777 /var/www/html/dvwa/external/ # Required by DVWA
echo "DVWA file permissions set."

# 6. Configure PHP Settings
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
sudo sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i 's/allow_url_include = Off/allow_url_include = On/g' /etc/php/${PHP_VERSION}/apache2/php.ini # Critical for some DVWA labs
sudo sed -i 's/display_errors = Off/display_errors = On/g' /etc/php/${PHP_VERSION}/apache2/php.ini # Good for debugging DVWA
sudo sed -i 's/display_startup_errors = Off/display_startup_errors = On/g' /etc/php/${PHP_VERSION}/apache2/php.ini # Good for debugging DVWA

echo "PHP settings configured."

# 7. Basic Apache Hardening
sudo sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf
echo "ServerTokens Prod" | sudo tee -a /etc/apache2/apache2.conf
echo "ServerSignature Off" | sudo tee -a /etc/apache2/apache2.conf
echo "Apache hardened."

# 8. Restart Apache
sudo systemctl restart apache2
echo "Apache restarted."

# 9. Configure UFW (Uncomplicated Firewall)
sudo ufw enable
sudo ufw allow ssh  # Port 22
sudo ufw allow http # Port 80
sudo ufw allow https # Port 443
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "UFW configured."

echo "DVWA setup complete!"

# IMPORTANT: You still need to manually navigate to http://<Public_IP>/dvwa/setup.php in your browser
# and click "Create / Reset Database" to initialize DVWA's database tables.
# You can get the public IP from Terraform outputs.