#!/bin/bash -ex
### Script cau hinh resouce cho LB
# Khai bao bien cho cac script 

source lb-config.cfg 

function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"

}

function add_resources {
        pcs resource create Virtual_IP_API ocf:heartbeat:IPaddr2 ip=$IP_VIP_API cidr_netmask=32 op monitor interval=30s
        pcs resource create Virtual_IP_DB ocf:heartbeat:IPaddr2 ip=$IP_VIP_DB cidr_netmask=32 op monitor interval=30s
        # pcs resource create Web_Cluster ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf status10url op monitor interval=5s
        pcs resource create Web_Cluster ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor interval=5s
        pcs constraint colocation set Web_Cluster Virtual_IP_API Virtual_IP_DB
        pcs constraint order set Virtual_IP_API Virtual_IP_DB sequential=false set Web_Cluster
}

#####
echocolor "Add resource"
add_resources

echocolor "DONE"

