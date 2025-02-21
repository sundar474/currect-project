#!/bin/bash

NAMES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "payment" "dispatch" "web" "shipping")
INSTANCE_TYPE=""
IMAGE_ID=ami-0b4f379183e5706b9
SECURITY_GROUP_ID=sg-07a1cb99873cf26ec
DOMAIN_NAME=sadhusundar.xyz 

# if mysql or mongodb or shipping instance_type should be t3.medium , for all others it is t2.micro

for i in "${NAMES[@]}"
do  
    if [[ $i == "mongodb" || $i == "mysql" || $i == "shipping" ]]
    then
        INSTANCE_TYPE="t3.medium"
    else
        INSTANCE_TYPE="t2.micro"
    fi
    echo "creating $i instance"
    IP_ADDRESS=$(aws ec2 run-instances --image-id $IMAGE_ID  --instance-type $INSTANCE_TYPE --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')
    echo "created $i instance: $IP_ADDRESS"

#     aws route53 change-resource-record-sets --hosted-zone-id Z0674372GGPOZJDZF41O --change-batch '
#     {
#             "Changes": [{
#             "Action": "CREATE",
#                         "ResourceRecordSet": {
#                             "Name": "'$i.$DOMAIN_NAME'",
#                             "Type": "A",
#                             "TTL": 300,
#                             "ResourceRecords": [{ "Value": "'$IP_ADDRESS'"}]
#                         }}]
#     }
#     '
# done


for i in service1 service2 web service3; do
    if [[ "$i" == *"web"* ]]; then
        VISIBILITY="Public"
    else
        VISIBILITY="Private"
    fi

    echo "Creating Route 53 record for $i with $VISIBILITY visibility"

    aws route53 change-resource-record-sets --hosted-zone-id Z0824164232GERUT9YSUC --change-batch '
    {
        "Changes": [{
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "'$i.$DOMAIN_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [{ "Value": "'$IP_ADDRESS'"}]
            }
        }]
    }'
done

# imporvement
# check instance is already created or not
# update route53 record