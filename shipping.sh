#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MYSQL_HOST=172.31.29.134

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


dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "roboshop user already exist...$Y SKIPPING $N"
fi

rm -rf /app &>> $LOGFILE
VALIDATE $? "clean up existing directory"

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

cp /home/centos/currect-project/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "Copying service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable shipping  &>> $LOGFILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing MySQL"

mysql -h -uroot 172.31.29.134 -pRoboShop@1 < /app/db/schema.sql &>> $LOGFILE

VALIDATE $? "validating scema"

mysql -h -uroot 172.31.29.134 -pRoboShop@1 < /app/db/app-user.sql &>> $LOGFILE

VALIDATE $? "validating user information"

mysql -h -uroot 172.31.29.134 -pRoboShop@1 < /app/db/master-data.sql &>> $LOGFILE

VALIDATE $? "validating master data"

systemctl restart shipping

VALIDATE $? "Restarted Shipping"