#!/bin/bash

############ Utils ############

# Function to display prompts
function prompt {
  if [ $1 -eq 1 ]; then
    echo "---> $2..."
    sleep 2
  else
    echo "---> $2."
    echo
  fi
}

############ Step 1: Set up Linux Environment ############

# Please refer to your virtual machine set up guide

# Optional, installing vim editor
# sudo apt-get install vim

# [Vim Tutorial]
# * To edit a file press "Insert" Key or "I"
# * To finish editing press "Esc" Key
# * To write the file press ":w"
# * To Exit the editor press ":q"
# * You can also write and quit ":wq" or ":x"

############ Step 2: Install Core Tech Stack ############

prompt 1 'Updating apt-get'
sudo apt-get update
prompt 0 'apt-get updated'

# Install Apache/MySQL/PHP
prompt 1 'Installing required tech stack (LAMP)'
sudo apt install apache2 mysql-client mysql-server php libapache2-mod-php
prompt 0 'Required tech stack installed'

# Setting up MySQL root password. Make sure to jot down your password, you may need it later
prompt 1 'Running mysql_secure_installation'
sudo mysql_secure_installation
prompt 0 'mysql_secure_installation setup complete'

############ Step 3: Install Additional Software ############

prompt 1 'Installing additional software'
sudo apt install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring
prompt 0 'Additional software installed'

# Restart Apache server so that the modules are loaded correctly
prompt 1 'Restarting Apache server'
sudo service apache2 restart
prompt 0 'Apache server restarted'

# Install Git
prompt 1 'Installing Git'
sudo apt install git
prompt 0 'Git installed'

############ Step 4: Download Moodle ############

prompt 1 'Downloading Moodle'
cd /opt
if [ ! -d moodle ]; then
  sudo git clone git://git.moodle.org/moodle.git
fi
cd moodle
prompt 0 'Moodle downloaded'

# Retrieve a list of each branch available and prompt user to select branch
prompt 1 'Below list are all the available versions'
sudo git branch -a
read -ep "---> Please indicate which version you'd like to use: " MY_BRANCH
sudo git branch --track ${MY_BRANCH} origin/${MY_BRANCH}

while [ $? -ne 0 ]; do
  read -ep 'Please enter a valid branch name: ' MY_BRANCH
  sudo git branch --track ${MY_BRANCH} origin/${MY_BRANCH}
done

sudo git checkout ${MY_BRANCH}
prompt 0 'Moodle version selected'

############ Step 5: Copy Moodle to Webroot Folder ############

prompt 1 'Copying Moodle to webroot folder'
sudo cp -R /opt/moodle /var/www/html/
if [ ! -d /var/moodledata ]; then
  sudo mkdir /var/moodledata
fi
sudo chown -R www-data /var/moodledata
sudo chmod -R 777 /var/moodledata
sudo chmod -R 0755 /var/www/html/moodle
prompt 0 'Done'

############ Step 6: Set up MySQL Server ############

# Optional, change default storage engine and file format
# sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf

# Scroll down to the [mysqld] section and under Basic Settings add the following line under the last statement:
# default_storage_engine = innodb
# innodb_file_per_table = 1
# innodb_file_format = Barracuda

# Note: If you use newer versions of MariaDB in Ubuntu 20.04 these changes in config file would arise and error (mysql unknown variable 'innodb_file_format=barracuda'), so comment or dont make these changes , these values are get by default.innodb_file_format was deprecated in MariaDB 10.2 and removed in MariaDB.

# Restart MySQL Server for changes to take affect
prompt 1 'Restarting MySQL'
sudo service mysql restart
prompt 0 'MySQL restarted'

# Set up Moodle database
prompt 1 'Creating database for Moodle'
sudo mysql -e 'CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
prompt 0 'Database created'

# Create a new user for database
read -ep '---> Enter a new user name for database: ' USER
while [ -z $USER ]; do
  read -ep '---> User name cannot be empty. Please re-enter: ' USER
done

echo "---> The password policy you've set up:"
mysql -e "SHOW VARIABLES LIKE 'validate_password%';"
read -sp "---> Enter a password for this user: (must comply with the password policy shown above, or you'll mostly likely get an error in next step) " USER_PASS
while [ -z $USER_PASS ]; do
  read -sp "\n---> Password cannot be empty. Please re-enter: " USER_PASS
done
echo

prompt 1 'Creating a new user'
sudo mysql -e "CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${USER_PASS}';"
while [ $? -ne 0 ]; do
  echo "---> Looks like some error occurs. Most likely, the password you just entered doesn't comply with the policy that you set up during mysql_secure_installation."
  read -sp '---> Please re-enter a valid password and try again (If you still have trouble, hit ^C to quit and set up your database manually.) ' USER_PASS
  echo
  sudo mysql -e "CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${USER_PASS}';"
done
prompt 0 'New user created'

prompt 1 'Grant privilege to new user'
sudo mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO '${USER}'@'localhost';"
prompt 0 'New user privilege granted'

############ Step 7: Complete setup ############

# Temporarily make the webroot writable for installer to automatically add config.php
prompt 1 'Temporarily make the webroot writable for config.php'
sudo chmod -R 777 /var/www/html/moodle
prompt 0 'Done'

echo '---> Automatic setup complete. Now you need to open the browser and go to http://IP.ADDRESS.OF.SERVER/moodle to finish installation.'
echo '---> After you have ran the installer and you have moodle setup, you NEED to revert permissions so that it is no longer writable, using the below command:'
echo 'sudo chmod -R 0755 /var/www/html/moodle'
echo '---> If you have any further questions please refer to https://docs.moodle.org/310/en/Step-by-step_Installation_Guide_for_Ubuntu for step-by-step setup guide.'

# Open your browser and go to http://IP.ADDRESS.OF.SERVER/moodle and follow the prompts to install Moodle
# 1. Change the path for moodledata: /var/moodledata
# 2. Database type: choose mysqli
# 3. Database settings:
#       Host server: localhost
#       Database: moodle
#       User: moodledude (the user you created when setting up the database)
#       Password: passwordformoodledude (the password for the user you created)
#       Tables Prefix: mdl_
# 4. Environment checks: This will indicate if any elements required to run moodle haven't been installed.
# 5. Next next next... (follow prompts and confirm installation)
# 6. Create a site admin account: create your moodle user account which will have site administrator permissions. The password you select has to meet certain security requirements.
# 7. Congrats! You can now start using Moodle!
# 8. Don't forget to revert permissions of your webroot:
# sudo chmod -R 0755 /var/www/html/moodle

############ System Paths After Install ############

# After installing Moodle you should set the system paths, this will provide better performance VS not setting them. Each entry in Moodle will have it's explanation.

# Navigate, on the moodle webpage, to Site Administration > Server > System Paths

# Input the following;

# Path to du: /usr/bin/du

# Path to apsell: /usr/bin/aspell

# Path to dot: /usr/bin/dot

# Save Changes
