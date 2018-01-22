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

function neutron_create_db {
      mysql -uroot -p$PASS_DATABASE_ROOT -h $DB1_IP_NIC2 -e "CREATE DATABASE neutron;
      GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';
      GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';
      FLUSH PRIVILEGES;"
}

function neutron_user_endpoint {
        openstack user create  neutron --domain default --password $NEUTRON_PASS
        openstack role add --project service --user neutron admin
        openstack service create --name neutron --description "OpenStack Networking" network
        
        openstack endpoint create --region RegionOne network public http://$IP_VIP_API:9696
        openstack endpoint create --region RegionOne network internal  http://$IP_VIP_API:9696
        openstack endpoint create --region RegionOne network admin  http://$IP_VIP_API:9696

}

function neutron_install {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            ssh root@$IP_ADD "yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables"
        done  

}

function neutron_config {
        ctl_neutron_conf=/etc/neutron/neutron.conf
        ctl_ml2_conf=/etc/neutron/plugins/ml2/ml2_conf.ini
        ctl_linuxbridge_agent=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
        cp $ctl_neutron_conf $ctl_neutron_conf.orig
        cp $ctl_ml2_conf $ctl_ml2_conf.orig
        cp $ctl_linuxbridge_agent $ctl_linuxbridge_agent.orig

        ops_edit $ctl_neutron_conf DEFAULT core_plugin ml2
        ops_edit $ctl_neutron_conf DEFAULT service_plugins router
        ops_edit $ctl_neutron_conf DEFAULT auth_strategy keystone    
        ops_edit $ctl_neutron_conf DEFAULT notify_nova_on_port_status_changes True
        ops_edit $ctl_neutron_conf DEFAULT notify_nova_on_port_data_changes True  
        ops_edit $ctl_neutron_conf DEFAULT allow_overlapping_ips True 
        ops_edit $ctl_neutron_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$MQ1_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ2_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ3_IP_NIC1:5672
        ops_edit $ctl_neutron_conf DEFAULT dhcp_agents_per_network 2
                
        ops_edit $ctl_neutron_conf database connection  mysql+pymysql://neutron:$PASS_DATABASE_NEUTRON@$IP_VIP_API/neutron
        
        ops_edit $ctl_neutron_conf oslo_messaging_rabbit rabbit_ha_queues true
        ops_edit $ctl_neutron_conf oslo_messaging_rabbit rabbit_retry_interval 1
        ops_edit $ctl_neutron_conf oslo_messaging_rabbit rabbit_retry_backoff 2
        ops_edit $ctl_neutron_conf oslo_messaging_rabbit rabbit_durable_queues true

        ops_edit $ctl_neutron_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $ctl_neutron_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $ctl_neutron_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $ctl_neutron_conf keystone_authtoken auth_type password
        ops_edit $ctl_neutron_conf keystone_authtoken project_domain_name Default
        ops_edit $ctl_neutron_conf keystone_authtoken user_domain_name Default
        ops_edit $ctl_neutron_conf keystone_authtoken project_name service
        ops_edit $ctl_neutron_conf keystone_authtoken username neutron
        ops_edit $ctl_neutron_conf keystone_authtoken password $NEUTRON_PASS
        
        
        ops_edit $ctl_neutron_conf nova auth_url http://$IP_VIP_API:35357
        ops_edit $ctl_neutron_conf nova auth_type password
        ops_edit $ctl_neutron_conf nova project_domain_name Default
        ops_edit $ctl_neutron_conf nova user_domain_name Default
        ops_edit $ctl_neutron_conf nova region_name RegionOne
        ops_edit $ctl_neutron_conf nova project_name service
        ops_edit $ctl_neutron_conf nova username nova
        ops_edit $ctl_neutron_conf nova password $NOVA_PASS
        
        ops_edit $ctl_neutron_conf oslo_concurrency lock_path /var/lib/neutron/tmp
        
        ops_edit $ctl_ml2_conf ml2 type_drivers flat,vlan,vxlan
        ops_edit $ctl_ml2_conf ml2 tenant_network_types vxlan
        ops_edit $ctl_ml2_conf ml2 mechanism_drivers linuxbridge,l2population
        ops_edit $ctl_ml2_conf ml2 extension_drivers port_security 

        ops_edit $ctl_ml2_conf ml2_type_flat flat_networks provider

        ops_edit $ctl_ml2_conf ml2_type_vxlan vni_ranges 1:1000
        
        ops_edit $ctl_ml2_conf securitygroup enable_ipset True
    
   
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do            
                scp $ctl_neutron_conf root@$IP_ADD:/etc/neutron/                 
                scp $ctl_ml2_conf root@$IP_ADD:/etc/neutron/plugins/ml2
                ssh root@$IP_ADD "ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini"
                ssh root@$IP_ADD "chown -R root:neutron /etc/neutron/"
        done
}

function neutron_syncdb {
        su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
            --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

}

function neutron_enable_restart {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            echocolor "Khoi dong dich vu NEUTRON tren $IP_ADD"
            ssh root@$IP_ADD "systemctl restart openstack-nova-api.service"
            ssh root@$IP_ADD "systemctl enable neutron-server.service"
            ssh root@$IP_ADD "systemctl start neutron-server.service"
        done  
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Bat dau cai dat NEUTRON"
echocolor "Tao DB NEUTRON"
sleep 3
neutron_create_db

echocolor "Tao user va endpoint cho NEUTRON"
sleep 3
neutron_user_endpoint

echocolor "Cai dat NEUTRON"
sleep 3
neutron_install

echocolor "Cau hinh cho NEUTRON"
sleep 3
neutron_config

echocolor "Dong bo DB cho NEUTRON"
sleep 3
neutron_syncdb

echocolor "Restart dich vu NEUTRON"
sleep 3
neutron_enable_restart

echocolor "Da cai dat xong NEUTRON"
