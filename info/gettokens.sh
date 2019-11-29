#!/bin/bash

ALIROLENAME=$(curl -s 'http://100.100.100.200/latest/meta-data/ram/security-credentials/')

if [[ $ALIROLENAME =~ "404 - Not Found" ]]; then
        echo 'I have not found attached RAM ROLE'
        exit 1
else
        echo "I have found attached RAM ROLE: $ALIROLENAME"
fi
 
sts_token=`curl -s "http://100.100.100.200/latest/meta-data/ram/security-credentials/$ALIROLENAME"`
export ALICLOUD_ACCESS_KEY=`echo $sts_token | jq  -r ".AccessKeyId"`
export ALICLOUD_SECRET_KEY=`echo $sts_token | jq -r ".AccessKeySecret"`
export ALICLOUD_SECURITY_TOKEN=`echo $sts_token | jq -r ".SecurityToken"`


#echo "ALICLOUD_ACCESS_KEY $ALICLOUD_ACCESS_KEY"


echo 'Token acquired...'

