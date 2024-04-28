#!/bin/bash
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

USEDMEMORY=$(free -m | awk 'NR==2{printf "%.2f\t", $3*100/$2 }')
TCP_CONN=$(netstat -an | wc -l)
TCP_CONN_PORT_3000=$(netstat -an | grep 3000 | wc -l)
TCP_CONN_PORT_443=$(netstat -an | grep 443 | wc -l)
IO_WAIT=$(iostat | awk 'NR==4 {print $5}')

aws cloudwatch put-metric-data --metric-name memory-usage --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $USEDMEMORY
aws cloudwatch put-metric-data --metric-name Tcp_connections --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN
aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_3000 --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN_PORT_3000
aws cloudwatch put-metric-data --metric-name IO_WAIT --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $IO_WAIT

aws cloudwatch put-metric-data --metric-name TCP_connection_on_port_443 --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $TCP_CONN_PORT_443
aws cloudwatch put-metric-data --metric-name HTTP_and_HTTPS_Connections --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $(($TCP_CONN_PORT_3000 + $TCP_CONN_PORT_443))

high_load=0
if [[ $IO_WAIT > 70 || $USEDMEMORY > 80 ]]
then
  high_load=1
fi
aws cloudwatch put-metric-data --metric-name High_Load --dimensions Instance=$INSTANCE_ID --namespace "Custom" --value $high_load
