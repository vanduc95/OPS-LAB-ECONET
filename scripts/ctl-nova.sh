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

function nova_create_db {
      mysql -uroot -p$PASS_DATABASE_ROOT -h $DB1_IP_NIC2 -e "CREATE DATABASE nova_api;
      GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
      GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
      CREATE DATABASE nova;
      GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA';
      GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA';
      CREATE DATABASE nova_cell0;
      GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA';
      GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA';

      FLUSH PRIVILEGES;"
}

function nova_user_endpoint {

        ## Create info for nova user
        echocolor "Create info for nova user"
        sleep 3

        openstack user create --domain default --password $NOVA_PASS nova
        openstack role add --project service --user nova admin
        openstack service create --name nova --description "OpenStack Compute" compute

        openstack endpoint create --region RegionOne compute public http://$IP_VIP_API:8774/v2.1
        openstack endpoint create --region RegionOne compute internal http://$IP_VIP_API:8774/v2.1
        openstack endpoint create --region RegionOne compute admin http://$IP_VIP_API:8774/v2.1

        ## Create info for placement user
        echocolor "Create info for placement user"
        sleep 3

        openstack user create --domain default --password $PLACEMENT_PASS placement
        openstack role add --project service --user placement admin
        openstack service create --name placement --description "Placement API" placement

        openstack endpoint create --region RegionOne placement public http://$IP_VIP_API:8778
        openstack endpoint create --region RegionOne placement internal http://$IP_VIP_API:8778
        openstack endpoint create --region RegionOne placement admin http://$IP_VIP_API:8778
}

function nova_install {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            ssh root@$IP_ADD "yum -y install openstack-nova-api openstack-nova-conductor \
                              openstack-nova-console openstack-nova-novncproxy \
                              openstack-nova-scheduler openstack-nova-placement-api"
        done  

}

function nova_config {
        ctl_nova_conf=/etc/nova/nova.conf
        cp $ctl_nova_conf $ctl_nova_conf.orig

        ops_edit $ctl_nova_conf DEFAULT enabled_apis osapi_compute,metadata
        ops_edit $ctl_nova_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$MQ1_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ2_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ3_IP_NIC1:5672
        ops_edit $ctl_nova_conf DEFAULT auth_strategy keystone
        ops_edit $ctl_nova_conf DEFAULT my_ip IP_ADDRESS
        ops_edit $ctl_nova_conf DEFAULT use_neutron True
        ops_edit $ctl_nova_conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
        ops_edit $ctl_nova_conf DEFAULT osapi_compute_listen \$my_ip
        ops_edit $ctl_nova_conf DEFAULT metadata_listen \$my_ip
        
        ops_edit $ctl_nova_conf api_database connection  mysql+pymysql://nova:$PASS_DATABASE_NOVA_API@$IP_VIP_DB/nova_api
        ops_edit $ctl_nova_conf database connection  mysql+pymysql://nova:$PASS_DATABASE_NOVA@$IP_VIP_DB/nova
        
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_ha_queues true
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_retry_interval 1
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_retry_backoff 2
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_durable_queues true

        ops_edit $ctl_nova_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $ctl_nova_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $ctl_nova_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $ctl_nova_conf keystone_authtoken auth_type password
        ops_edit $ctl_nova_conf keystone_authtoken project_domain_name Default
        ops_edit $ctl_nova_conf keystone_authtoken user_domain_name Default
        ops_edit $ctl_nova_conf keystone_authtoken project_name service
        ops_edit $ctl_nova_conf keystone_authtoken username nova
        ops_edit $ctl_nova_conf keystone_authtoken password $NOVA_PASS

        ops_edit $ctl_nova_conf vnc enabled true   
        ops_edit $ctl_nova_conf vnc vncserver_listen \$my_ip
        ops_edit $ctl_nova_conf vnc vncserver_proxyclient_address \$my_ip
        # ops_edit $ctl_nova_conf vnc novncproxy_host \$my_ip
        
        ops_edit $ctl_nova_conf glance api_servers http://$IP_VIP_API:9292
        
        ops_edit $ctl_nova_conf oslo_concurrency lock_path /var/lib/nova/tmp

        ops_edit $ctl_nova_conf placement os_region_name RegionOne
        ops_edit $ctl_nova_conf placement project_domain_name Default
        ops_edit $ctl_nova_conf placement project_name service
        ops_edit $ctl_nova_conf placement auth_type password
        ops_edit $ctl_nova_conf placement user_domain_name Default
        ops_edit $ctl_nova_conf placement auth_url http://$IP_VIP_API:35357/v3
        ops_edit $ctl_nova_conf placement username placement
        ops_edit $ctl_nova_conf placement password $PLACEMENT_PASS

        ops_edit $ctl_nova_conf neutron url http://$IP_VIP_API:9696
        ops_edit $ctl_nova_conf neutron auth_url http://$IP_VIP_API:35357
        ops_edit $ctl_nova_conf neutron auth_type password
        ops_edit $ctl_nova_conf neutron project_domain_name Default
        ops_edit $ctl_nova_conf neutron user_domain_name Default
        ops_edit $ctl_nova_conf neutron project_name service
        ops_edit $ctl_nova_conf neutron username neutron
        ops_edit $ctl_nova_conf neutron password $NEUTRON_PASS
        ops_edit $ctl_nova_conf neutron service_metadata_proxy true
        ops_edit $ctl_nova_conf neutron metadata_proxy_shared_secret $METADATA_SECRET

        
        ops_edit $ctl_nova_conf scheduler discover_hosts_in_cells_interval 300
        
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3 
        do      
                echocolor "Copytile cau hinh cho $IP_ADD"
                scp $ctl_nova_conf root@$IP_ADD:/etc/nova/                                
        done
        
        ssh root@$CTL1_IP_NIC3 "sed -i 's/IP_ADDRESS/$CTL1_IP_NIC1/g' $ctl_nova_conf"  
        ssh root@$CTL2_IP_NIC3 "sed -i 's/IP_ADDRESS/$CTL2_IP_NIC1/g' $ctl_nova_conf"  
        ssh root@$CTL3_IP_NIC3 "sed -i 's/IP_ADDRESS/$CTL3_IP_NIC1/g' $ctl_nova_conf"  
}

function add_config_httpd {

echo "
<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>" >> /etc/httpd/conf.d/00-nova-placement-api.conf

}

function restart_httpd {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3 
        do      
            echocolor "Add file cau hinh cho $IP_ADD"
            ssh root@$IP_ADD "$(typeset -f); add_config_httpd"
            ssh root@$IP_ADD "systemctl restart httpd"
        done
}

function nova_syncdb {
        su -s /bin/sh -c "nova-manage api_db sync" nova
        su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
        su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
        su -s /bin/sh -c "nova-manage db sync" nova
        nova-manage cell_v2 list_cells

}

function nova_enable_restart {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            echocolor "Restart dich vu nova tren $IP_ADD"
            ssh root@$IP_ADD "systemctl enable openstack-nova-api.service"
            ssh root@$IP_ADD "systemctl enable openstack-nova-consoleauth.service"
            ssh root@$IP_ADD "systemctl enable openstack-nova-scheduler.service"
            ssh root@$IP_ADD "systemctl enable openstack-nova-conductor.service"
            ssh root@$IP_ADD "systemctl enable openstack-nova-novncproxy.service"
            
            ssh root@$IP_ADD "systemctl start openstack-nova-api.service"
            ssh root@$IP_ADD "systemctl start openstack-nova-consoleauth.service"
            ssh root@$IP_ADD "systemctl start openstack-nova-scheduler.service"
            ssh root@$IP_ADD "systemctl start openstack-nova-conductor.service"
            ssh root@$IP_ADD "systemctl start openstack-nova-novncproxy.service"
        done  
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Bat dau cai dat NOVA"
echocolor "Tao DB NOVA"
sleep 3
nova_create_db

echocolor "Tao user va endpoint cho NOVA"
sleep 3
nova_user_endpoint

echocolor "Cai dat NOVA"
sleep 3
nova_install

echocolor "Cau hinh cho NOVA"
sleep 3
nova_config
restart_httpd

echocolor "Dong bo DB cho NOVA"
sleep 3
nova_syncdb

echocolor "Restart dich vu NOVA"
sleep 3
nova_enable_restart

echocolor "Da cai dat xong NOVA"
