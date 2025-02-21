#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename $0 .sh)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
ROOT_PASS="RoboShop@1"
  
VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling MySQL server"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Starting MySQL Server"

# Setting MySQL root password automatically without prompt
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS';" &>>$LOGFILE
VALIDATE $? "Setting MySQL root password"

# Creating a .my.cnf file to avoid password prompt for MySQL commands
echo -e "[client]\nuser=root\npassword=$ROOT_PASS" > ~/.my.cnf
chmod 600 ~/.my.cnf
VALIDATE $? "Configuring MySQL Client Auto-Login"

# Grant privileges and secure MySQL
echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;" | mysql &>>$LOGFILE
VALIDATE $? "Configuring MySQL User Permissions"

# Configure MySQL to allow remote connections
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf.d/mysqld.cnf
VALIDATE $? "Configuring MySQL to accept remote connections"

# Restart MySQL to apply changes
systemctl restart mysqld &>>$LOGFILE
VALIDATE $? "Restarting MySQL Server after configuration change"

# Allow remote MySQL access
echo "CREATE USER 'root'@'%' IDENTIFIED BY '$ROOT_PASS';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;" | mysql &>>$LOGFILE
VALIDATE $? "Allowing Remote MySQL Access"

# Open firewall for MySQL (port 3306)
firewall-cmd --permanent --add-service=mysql &>>$LOGFILE
firewall-cmd --reload &>>$LOGFILE
VALIDATE $? "Configuring Firewall to Allow Remote MySQL Access"

# Restart MySQL service
systemctl restart mysqld &>>$LOGFILE
VALIDATE $? "Restarting MySQL Server"

echo "MySQL setup completed successfully."
