#!/bin/bash
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

USEDMEMORY=$(free -m | awk 'NR==2{printf "%.2f\t", $3*100/$2 }')
TCP_CONN=$(netstat -an | wc -l)
TCP_CONN_PORT_27017=$(netstat -an | grep 27017 | wc -l)
SSH_TCP_CONN_PORT_22=$(netstat -an | grep 22 | wc -l)
IO_WAIT=$(iostat | awk 'NR==4 {print $5}')

aws cloudwatch put-metric-data --metric-name memory-usage --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $USEDMEMORY
aws cloudwatch put-metric-data --metric-name Tcp_connections --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN
aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_27017 --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN_PORT_27017
aws cloudwatch put-metric-data --metric-name SSH_TCP_connections_on_port_22 --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $SSH_TCP_CONN_PORT_22
aws cloudwatch put-metric-data --metric-name IO_WAIT --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $IO_WAIT

ssh_active=0
if [[ $SSH_TCP_CONN_PORT_22 > 4  ]]
then
  ssh_active=1
fi
aws cloudwatch put-metric-data --metric-name SSH_Connection_Active --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $ssh_active

db_active=0
if [[ $TCP_CONN_PORT_27017 > 2  ]]
then
  db_active=1
fi
aws cloudwatch put-metric-data --metric-name Database_Connection_Active --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $db_active

high_load=0
if [[ $IO_WAIT > 70 || $USEDMEMORY > 80 ]]
then
  high_load=1
fi
aws cloudwatch put-metric-data --metric-name High_Load --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $high_load

