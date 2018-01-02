#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

### Khai bao bien de thuc hien
cat <<EOF> /root/ctl-config.cfg
## Hostname
### Hostname cho cac may CONTROLLER
CTL1_HOSTNAME=ctl1
CTL2_HOSTNAME=ctl2
CTL3_HOSTNAME=ctl3

## IP Address CONTROLLER
### IP cho bond0 cho cac may CONTROLLER
CTL1_IP_NIC1=10.10.20.71
CTL2_IP_NIC1=10.10.20.72
CTL3_IP_NIC1=10.10.20.73

### IP cho bond1 cho cac may CONTROLLER
CTL1_IP_NIC2=10.10.10.71
CTL2_IP_NIC2=10.10.10.72
CTL3_IP_NIC2=10.10.10.73

### IP cho bond3 cho cac may CONTROLLER
CTL1_IP_NIC3=192.168.20.71
CTL2_IP_NIC3=192.168.20.72
CTL3_IP_NIC3=192.168.20.73



### Hostname cho cac may NETWORK
NET1_HOSTNAME=net1
NET2_HOSTNAME=net2

## IP Address NETWORK
### IP cho NIC1 - API cho cac may NETWORK
NET1_IP_NIC1=10.10.20.77
NET2_IP_NIC1=10.10.20.78


### IP cho NIC2 - DB_MQ cho cac may NETWORK
NET1_IP_NIC2=10.10.10.77
NET2_IP_NIC2=10.10.10.78


### IP cho NIC3 - Provider VM cho cac may NETWORK
NET1_IP_NIC3=192.168.50.77
NET2_IP_NIC3=192.168.50.78


### IP cho NIC4 - Provider VM cho cac may NETWORK
NET1_IP_NIC4=192.168.20.77
NET2_IP_NIC4=192.168.20.78


### IP cho NIC5 - DATA_VM cho cac may NETWORK
NET1_IP_NIC5=172.16.20.77
NET2_IP_NIC5=172.16.20.78



### Hostname cho cac may COMPUTE
COM1_HOSTNAME=com1
COM2_HOSTNAME=com2

## IP Address COMPUTE
### IP cho NIC1 - API cho cac may COMPUTE
COM1_IP_NIC1=10.10.20.81
COM2_IP_NIC1=10.10.20.82


### IP cho NIC2 - DB_MQ cho cac may COMPUTE
COM1_IP_NIC2=10.10.10.81
COM2_IP_NIC2=10.10.10.82


### IP cho NIC3 - Provider VM cho cac may COMPUTE
COM1_IP_NIC3=192.168.50.81
COM2_IP_NIC3=192.168.50.82


### IP cho NIC4 - Provider VM cho cac may COMPUTE
COM1_IP_NIC4=192.168.20.81
COM2_IP_NIC4=192.168.20.82


### IP cho NIC5 - DATA_VM cho cac may COMPUTE
COM1_IP_NIC5=172.16.20.81
COM2_IP_NIC5=172.16.20.82



#########DB
## Hostname
### Hostname cho cac may DB
DB1_HOSTNAME=db1
DB2_HOSTNAME=db2
DB3_HOSTNAME=db3

## IP Address
### IP cho bond0 cho cac may DB
DB1_IP_NIC1=10.10.10.71
DB2_IP_NIC1=10.10.10.72
DB3_IP_NIC1=10.10.10.73

### IP cho bond1 cho cac may DB
DB1_IP_NIC2=192.168.20.71
DB2_IP_NIC2=192.168.20.72
DB3_IP_NIC2=192.168.20.73

### Hostname cho cac may rabbitmq
MQ1_HOSTNAME=mq1
MQ2_HOSTNAME=mq2
MQ3_HOSTNAME=mq3

## IP Address
### IP cho bond0 cho cac may rabbitmq
MQ1_IP_NIC1=10.10.10.71
MQ2_IP_NIC1=10.10.10.72
MQ3_IP_NIC1=10.10.10.73

### IP cho bond1 cho cac may rabbitmq
MQ1_IP_NIC2=192.168.20.71
MQ2_IP_NIC2=192.168.20.72
MQ3_IP_NIC2=192.168.20.73

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

# ###IP cho bond3 cho cac may LoadBalancer
# LB1_IP_NIC4=192.168.40.61
# LB2_IP_NIC4=192.168.40.62

##MAT KHAU CHUNG
PASS_CLUSTER='Ec0net2017'
PASS_RABBIT='Ec0net2017'
RABBIT_PASS='Ec0net2017'
PASS_DATABASE_ROOT='Ec0net2017'

### Password cho MariaDB
PASS_DATABASE_KEYSTONE=\$PASS_DATABASE_ROOT
PASS_DATABASE_NOVA=\$PASS_DATABASE_ROOT
PASS_DATABASE_NOVA_API=\$PASS_DATABASE_ROOT
PASS_DATABASE_NEUTRON=\$PASS_DATABASE_ROOT
PASS_DATABASE_GLANCE=\$PASS_DATABASE_ROOT
PASS_DATABASE_CINDER=\$PASS_DATABASE_ROOT
PASS_DATABASE_CEILOMTER=\$PASS_DATABASE_ROOT
PASS_DATABASE_AODH=\$PASS_DATABASE_ROOT
PASS_DATABASE_GNOCCHI=\$PASS_DATABASE_ROOT

### Password openstack service
METADATA_SECRET=\$PASS_DATABASE_ROOT
ADMIN_PASS=\$PASS_DATABASE_ROOT
DEMO_PASS=\$PASS_DATABASE_ROOT
GLANCE_PASS=\$PASS_DATABASE_ROOT
NOVA_PASS=\$PASS_DATABASE_ROOT
PLACEMENT_PASS=\$PASS_DATABASE_ROOT
NOVA_API_PASS=\$PASS_DATABASE_ROOT
CINDER_PASS=\$PASS_DATABASE_ROOT
NEUTRON_PASS=\$PASS_DATABASE_ROOT
CEILOMETER_PASS=\$PASS_DATABASE_ROOT
GNOCCHI_PASS=\$PASS_DATABASE_ROOT
AODH_PASS=\$PASS_DATABASE_ROOT
EOF

chmod +x ctl-config.cfg
source ctl-config.cfg

function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"

}

function ops_edit {
    crudini --set $1 $2 $3 $4
}


function ops_del {
    crudini --del $1 $2 $3
}

function copykey {
        ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
        for IP_ADD in $COM1_IP_NIC4 $COM2_IP_NIC4
        do
                ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$IP_ADD
        done
}

function setup_config {
        for IP_ADD in $COM1_IP_NIC4 $COM2_IP_NIC4
        do
                scp /root/ctl-config.cfg root@$IP_ADD:/root/
                chmod +x ctl-config.cfg

        done
}


function install_repo() {
        yum -y install centos-release-openstack-pike
        yum -y upgrade
        yum -y install crudini wget vim
        yum -y install python-openstackclient openstack-selinux
        
}

function khai_bao_host {
        source ctl-config.cfg
        echo "$CTL1_IP_NIC3 ctl1" >> /etc/hosts
        echo "$CTL2_IP_NIC3 ctl2" >> /etc/hosts
        echo "$CTL3_IP_NIC3 ctl3" >> /etc/hosts
        echo "$COM1_IP_NIC4 com1" >> /etc/hosts
        echo "$COM2_IP_NIC4 com2" >> /etc/hosts
        echo "$NET1_IP_NIC4 net1" >> /etc/hosts
        echo "$NET2_IP_NIC4 net2" >> /etc/hosts
        # scp /etc/hosts root@$COM2_IP_NIC4:/etc/
}


function install_ntp_server {
        yum -y install chrony       
        echocolor "Cau hinh NTP cho `hostname`"
        sleep 3             
        sed -i "s/server 0.centos.pool.ntp.org iburst/server $CTL1_IP_NIC3 iburst/g" /etc/chrony.conf
        sed -i "s/server 1.centos.pool.ntp.org iburst/#/g" /etc/chrony.conf
        sed -i "s/server 2.centos.pool.ntp.org iburst/#/g" /etc/chrony.conf
        sed -i "s/server 3.centos.pool.ntp.org iburst/#/g" /etc/chrony.conf
        systemctl enable chronyd.service
        systemctl start chronyd.service
        systemctl restart chronyd.service
        chronyc sources
}


##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################

echocolor "Cai dat cac goi chuan bi tren COMPUTE"

# echocolor "Tao key va copy key, bien khai bao sang cac node"
# sleep 3
# copykey
# setup_config

# sleep 3

# for IP_ADD in $COM1_IP_NIC4 $COM2_IP_NIC4
# do 

#     echocolor "Cai dat repo tren $IP_ADD"
#     sleep 3
#     ssh root@$IP_ADD "$(typeset -f); install_repo"  
#     if [ "$IP_ADD" == "$COM1_IP_NIC4" ]; then
#       echocolor "Cai dat khai_bao_host tren $IP_ADD"
#       sleep 3
#       ssh root@$IP_ADD "$(typeset -f); khai_bao_host"
#     fi 
# done 


sleep 3
echocolor "install_repo"
install_repo

echocolor "Khai bao hosts"
khai_bao_host

echocolor "Cai dat NTP "
install_ntp_server

echocolor "DONE"

