#!/bin/bash

# Define MySQL root password
ROOT_PASSWORD="RoboShop@1"
LOGFILE="/var/log/mysql_setup.log"

# Function to validate commands
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo "$2 ... FAILED"
        exit 1
    else
        echo "$2 ... SUCCESS"
    fi
}

# Install MySQL Server
dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Server"

# Enable MySQL service
systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling MySQL server"

# Start MySQL service
systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Starting MySQL server"

# Wait for MySQL service to start completely
sleep 5

# Check MySQL service status
if ! systemctl is-active --quiet mysqld; then
    echo "MySQL service is not running. Exiting."
    exit 1
fi

# Set root password manually to avoid the error
sudo mysql --connect-expired-password -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';
EOF

# Login and execute required MySQL commands
sudo mysql -u root -p$ROOT_PASSWORD <<EOF
CREATE USER 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Restart MySQL service to apply changes
sudo systemctl restart mysqld

echo "MySQL root password has been changed and privileges have been granted successfully."
