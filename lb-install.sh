#!/bin/bash -ex
### Script cai dat LoadBalancer
# Khai bao bien cho cac script 
cat <<EOF> /root/lb-config.cfg
## Hostname
### Hostname cho cac may LoadBalancer
LB1_HOSTNAME=lb1
LB2_HOSTNAME=lb2

##IP Address
### IP VIP
IP_VIP_ADMIN=192.168.20.60
IP_VIP_DB=10.10.10.60
IP_VIP_API=10.10.20.60

###IP cho bond0 cho cac may LoadBalancer
LB1_IP_NIC1=10.10.20.61
LB2_IP_NIC1=10.10.20.62

###IP cho bond1 cho cac may LoadBalancer
LB1_IP_NIC2=10.10.10.61
LB2_IP_NIC2=10.10.10.62

###IP cho bond2 cho cac may LoadBalancer
LB1_IP_NIC3=192.168.20.61
LB2_IP_NIC3=192.168.20.62


###MAT KHAU
PASS_CLUSTER='Ec0net2017'

EOF

source lb-config.cfg 

function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"

}


function copykey {
        ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
        for IP_ADD in $LB1_IP_NIC3 $LB2_IP_NIC3
        do
                ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$IP_ADD
        done
}


function setup_config {
        for IP_ADD in $LB1_IP_NIC3 $LB2_IP_NIC3
        do
                scp /root/lb-config.cfg root@$IP_ADD:/root/
                chmod +x lb-config.cfg
        done
}


function khai_bao_host() {
        source lb-config.cfg
        echo "$LB1_IP_NIC3 $LB1_HOSTNAME" >> /etc/hosts
        echo "$LB2_IP_NIC3 $LB2_HOSTNAME" >> /etc/hosts
        scp /etc/hosts root@$LB2_IP_NIC3:/etc/
                
}


function install_nginx {
        yum -y install wget vim

cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF

        yum -y install nginx
        systemctl start nginx 
        systemctl enable nginx

        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
}


function install_pacemaker_corosync {
        source lb-config.cfg
        yum -y install pacemaker pcs
        systemctl start pcsd 
        systemctl enable pcsd
        echo $PASS_CLUSTER | passwd --stdin hacluster    
}


function config_cluster {
        source lb-config.cfg
        pcs cluster auth $LB1_HOSTNAME $LB2_HOSTNAME -u hacluster -p $PASS_CLUSTER --force
        pcs cluster setup --name ha_cluster $LB1_HOSTNAME $LB2_HOSTNAME
        pcs cluster start --all
        pcs cluster enable --all
        pcs property set stonith-enabled=false
        pcs property set default-resource-stickiness="INFINITY"       
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Cai dat lb"
sleep 3


echocolor "Tao key va copy key, bien khai bao sang cac node"
sleep 3
copykey
setup_config


echocolor "Khai bao host"
sleep 3
khai_bao_host


echocolor "Cai dat Nginx"
for IP_ADD in $LB1_IP_NIC3 $LB2_IP_NIC3
do 
  echocolor "Cai dat install_nginx tren $IP_ADD"
  sleep 3
  ssh root@$IP_ADD "$(typeset -f); install_nginx"   
done 


echocolor "Cai dat pacemaker_corosync"
for IP_ADD in $LB1_IP_NIC3 $LB2_IP_NIC3
do 
  echocolor "Cai dat install_pacemaker_corosync tren $IP_ADD"
  sleep 3
  ssh root@$IP_ADD "$(typeset -f); install_pacemaker_corosync"    
done 


echocolor "Cau hinh pacemaker_corosync"
sleep 3
config_cluster


echocolor "DONE"