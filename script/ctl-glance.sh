#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

### Khai bao bien de thuc hien

source ctl-config.cfg
source admin-openrc

function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"

}

function ops_edit {
    crudini --set $1 $2 $3 $4
}


# Ham de del mot dong trong file cau hinh
function ops_del {
    crudini --del $1 $2 $3
}

function glance_create_db {
mysql -uroot -p$PASS_DATABASE_ROOT -h $DB1_IP_NIC2 -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$PASS_DATABASE_GLANCE';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$PASS_DATABASE_GLANCE';
FLUSH PRIVILEGES;"
}

function glance_user_endpoint {
        openstack user create  glance --domain default --password $GLANCE_PASS
        openstack role add --project service --user glance admin
        openstack service create --name glance --description "OpenStack Image" image
        openstack endpoint create --region RegionOne image public http://$IP_VIP_API:9292
        openstack endpoint create --region RegionOne image internal http://$IP_VIP_API:9292
        openstack endpoint create --region RegionOne image admin http://$IP_VIP_API:9292
}

function glance_install {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            ssh root@$IP_ADD "yum -y install openstack-glance"
        done  

}

function glance_config {
        glance_api_conf=/etc/glance/glance-api.conf
        glance_registry_conf=/etc/glance/glance-registry.conf
        cp $glance_api_conf $glance_api_conf.orig
        cp $glance_registry_conf $glance_registry_conf.orig

        ###glance_api_conf
        ops_edit $glance_api_conf glance_store stores file,http
        ops_edit $glance_api_conf glance_store default_store file
        ops_edit $glance_api_conf glance_store filesystem_store_datadir /var/lib/glance/images/

        ops_edit $glance_api_conf database connection mysql+pymysql://glance:$PASS_DATABASE_GLANCE@$IP_VIP_DB/glance

        ops_edit $glance_api_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $glance_api_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $glance_api_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $glance_api_conf keystone_authtoken auth_type password
        ops_edit $glance_api_conf keystone_authtoken project_domain_name Default
        ops_edit $glance_api_conf keystone_authtoken user_domain_name Default
        ops_edit $glance_api_conf keystone_authtoken project_name service
        ops_edit $glance_api_conf keystone_authtoken username glance
        ops_edit $glance_api_conf keystone_authtoken password $GLANCE_PASS

        ops_edit $glance_api_conf paste_deploy flavor keystone
        
        
        ###glance_registry_conf
        ops_edit $glance_registry_conf database connection mysql+pymysql://glance:$PASS_DATABASE_GLANCE@$IP_VIP_DB/glance

        ops_edit $glance_registry_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $glance_registry_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $glance_registry_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $glance_registry_conf keystone_authtoken auth_type password
        ops_edit $glance_registry_conf keystone_authtoken project_domain_name Default
        ops_edit $glance_registry_conf keystone_authtoken user_domain_name Default
        ops_edit $glance_registry_conf keystone_authtoken project_name service
        ops_edit $glance_registry_conf keystone_authtoken username glance
        ops_edit $glance_registry_conf keystone_authtoken password $GLANCE_PASS

        ops_edit $glance_registry_conf paste_deploy flavor keystone

}
function glance_syncdb {
        su -s /bin/sh -c "glance-manage db_sync" glance
        for IP_ADD in $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            scp $glance_api_conf root@$IP_ADD:/etc/glance/
            scp $glance_registry_conf root@$IP_ADD:/etc/glance/
        done
}


function glance_enable_restart {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            ssh root@$IP_ADD "systemctl enable openstack-glance-api.service"
            ssh root@$IP_ADD "systemctl enable openstack-glance-registry.service"
            ssh root@$IP_ADD "systemctl start openstack-glance-api.service"
            ssh root@$IP_ADD "systemctl start openstack-glance-registry.service"
        done  
}

function glance_create_image {
        wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
        openstack image create "cirros" --file cirros-0.3.4-x86_64-disk.img \
        --disk-format qcow2 --container-format bare \
        --public
        
        openstack image list       
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Bat dau cai dat Glance"
echocolor "Tao DB Glance"
sleep 3
glance_create_db

echocolor "Tao user va endpoint cho Glance"
sleep 3
glance_user_endpoint

echocolor "Cai dat Glance"
sleep 3
glance_install

echocolor "Cau hinh cho Glance"
sleep 3
glance_config

echocolor "Dong bo DB cho Glance"
sleep 3
glance_syncdb

echocolor "Restart dich vu glance"
sleep 3
glance_enable_restart

echocolor "Tao images"
sleep 3
glance_create_image

echocolor "Da cai dat xong Glance"
