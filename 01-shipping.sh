#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MYSQL_HOST=172.31.16.173
MYSQL_USER="root"
MYSQL_PASSWORD="RoboShop@1"

VALIDATE(){
   if [ $1 -ne 0 ]; then
        echo -e "$2...$R FAILURE $N"
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]; then
    echo "Please run this script with root access."
    exit 1
else
    echo "You are super user."
fi

dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "roboshop user already exists...$Y SKIPPING $N"
fi

rm -rf /app &>> $LOGFILE
VALIDATE $? "Clean up existing directory"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOGFILE
VALIDATE $? "Downloading shipping application"

cd /app  &>> $LOGFILE
VALIDATE $? "Moving to app directory"

unzip /tmp/shipping.zip &>> $LOGFILE
VALIDATE $? "Extracting shipping application"

mvn clean package &>> $LOGFILE
VALIDATE $? "Packaging shipping"

mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "Renaming the artifact"

cp /home/centos/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "Copying service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable shipping &>> $LOGFILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing MySQL"

# Load Schema Files (Ignoring Errors)
mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD < /app/db/schema.sql &>> $LOGFILE || true
VALIDATE $? "Loading schema.sql (Errors ignored)"

mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD < /app/db/app-user.sql &>> $LOGFILE || true
VALIDATE $? "Loading app-user.sql (Errors ignored)"

mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD < /app/db/master-data.sql &>> $LOGFILE || true
VALIDATE $? "Loading master-data.sql (Errors ignored)"

systemctl restart shipping
VALIDATE $? "Restarted Shipping"