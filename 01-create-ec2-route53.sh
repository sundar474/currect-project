#!/bin/bash

NAMES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
INSTANCE_TYPE=""
IMAGE_ID=ami-0b4f379183e5706b9
SECURITY_GROUP_ID=sg-07a1cb99873cf26ec
DOMAIN_NAME=sadhusundar.xyz 

# if mysql or mongodb or shipping instance_type should be t3.medium , for all others it is t2.micro

for i in "${NAMES[@]}"; do  
    if [[ $i == "mongodb" || $i == "mysql" || $i == "shipping" ]]; then
        INSTANCE_TYPE="t3.medium"
    else
        INSTANCE_TYPE="t2.micro"
    fi
    
    echo "Creating $i instance"
    
    IP_ADDRESS=$(aws ec2 run-instances --image-id $IMAGE_ID  --instance-type $INSTANCE_TYPE --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')

    echo "Created $i instance: $IP_ADDRESS"

    # Now creating Route 53 records
    for j in service1 service2 web service3; do  # Changed loop variable to 'j'
        if [[ "$j" == *"web"* ]]; then
            VISIBILITY="Public"
        else
            VISIBILITY="Private"
        fi

        echo "Creating Route 53 record for $j with $VISIBILITY visibility"

        aws route53 change-resource-record-sets --hosted-zone-id Z0824164232GERUT9YSUC --change-batch '
        {
                "Changes": [{
                "Action": "CREATE",
                            "ResourceRecordSet": {
                                "Name": "'$j.$DOMAIN_NAME'",
                                "Type": "A",
                                "TTL": 1,
                                "ResourceRecords": [{ "Value": "'$IP_ADDRESS'"}]
                            }}]
        }
        '
    done
done  # Closing the first loop properly