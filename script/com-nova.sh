#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

source ctl-config.cfg

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

function com_nova_install {
        yum install -y openstack-nova-compute
}

function com_nova_config {
        com_nova_conf=/etc/nova/nova.conf
        cp $com_nova_conf $com_nova_conf.orig

        ops_edit $com_nova_conf DEFAULT enabled_apis osapi_compute,metadata
        ops_edit $com_nova_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$MQ1_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ2_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ3_IP_NIC1:5672
        ops_edit $com_nova_conf DEFAULT auth_strategy keystone
        ops_edit $com_nova_conf DEFAULT my_ip $(ip addr show dev ens256 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
        ops_edit $com_nova_conf DEFAULT use_neutron true
        ops_edit $com_nova_conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_ha_queues true
        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_retry_interval 1
        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_retry_backoff 2
        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_durable_queues true

        ops_edit $com_nova_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $com_nova_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $com_nova_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $com_nova_conf keystone_authtoken auth_type password
        ops_edit $com_nova_conf keystone_authtoken project_domain_name Default
        ops_edit $com_nova_conf keystone_authtoken user_domain_name Default
        ops_edit $com_nova_conf keystone_authtoken project_name service
        ops_edit $com_nova_conf keystone_authtoken username nova
        ops_edit $com_nova_conf keystone_authtoken password $NOVA_PASS

        ops_edit $com_nova_conf vnc enabled True
        ops_edit $com_nova_conf vnc vncserver_listen 0.0.0.0
        ops_edit $com_nova_conf vnc vncserver_proxyclient_address \$my_ip
        ops_edit $com_nova_conf vnc novncproxy_base_url http://$IP_VIP_ADMIN:6080/vnc_auto.html
        # ops_edit $com_nova_conf vnc novncproxy_base_url http://192.168.20.71:6080/vnc_auto.html
        
        ops_edit $com_nova_conf glance api_servers http://$IP_VIP_API:9292
        
        ops_edit $com_nova_conf oslo_concurrency lock_path /var/lib/nova/tmp
        
        ops_edit $com_nova_conf neutron url http://$IP_VIP_API:9696
        ops_edit $com_nova_conf neutron auth_url http://$IP_VIP_API:35357
        ops_edit $com_nova_conf neutron auth_type password
        ops_edit $com_nova_conf neutron project_domain_name Default
        ops_edit $com_nova_conf neutron user_domain_name Default
        ops_edit $com_nova_conf neutron project_name service
        ops_edit $com_nova_conf neutron username neutron
        ops_edit $com_nova_conf neutron password $NEUTRON_PASS


        ops_edit $com_nova_conf placement os_region_name RegionOne
        ops_edit $com_nova_conf placement project_domain_name Default
        ops_edit $com_nova_conf placement project_name service
        ops_edit $com_nova_conf placement auth_type password
        ops_edit $com_nova_conf placement user_domain_name Default
        ops_edit $com_nova_conf placement auth_url http://$IP_VIP_API:35357/v3
        ops_edit $com_nova_conf placement username placement
        ops_edit $com_nova_conf placement password $PLACEMENT_PASS
        
        ops_edit $com_nova_conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)
 
}

function com_nova_restart {
        systemctl enable libvirtd.service openstack-nova-compute.service
        systemctl start libvirtd.service openstack-nova-compute.service
}


##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################

echocolor "Install dich vu NOVA"
sleep 3
com_nova_install

echocolor "Config dich vu NOVA"
sleep 3
com_nova_config

echocolor "Restart dich vu NOVA"
sleep 3
com_nova_restart

