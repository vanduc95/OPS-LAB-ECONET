#!/bin/bash -ex 
##############################################################################


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


function com_neutron_install {
        yum install -y  openstack-neutron-linuxbridge ebtables ipset
}

function com_neutron_config {

        LOCAL_IP=`ip -o -4 addr show dev ens161 | sed 's/.* inet \([^/]*\).*/\1/'| head -n 1`

        com_neutron_conf=/etc/neutron/neutron.conf
        com_linuxbridge_agent=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
        
        
        cp $com_neutron_conf $com_neutron_conf.orig
        cp $com_linuxbridge_agent $com_linuxbridge_agent.orig

        
        ops_edit $com_neutron_conf DEFAULT auth_strategy keystone
        ops_edit $com_neutron_conf DEFAULT core_plugin ml2
        ops_edit $com_neutron_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$MQ1_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ2_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ3_IP_NIC1:5672

        
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_ha_queues true
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_retry_interval 1
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_retry_backoff 2
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_durable_queues true
        
        ops_edit $com_neutron_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $com_neutron_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $com_neutron_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $com_neutron_conf keystone_authtoken auth_type password
        ops_edit $com_neutron_conf keystone_authtoken project_domain_name Default
        ops_edit $com_neutron_conf keystone_authtoken user_domain_name Default
        ops_edit $com_neutron_conf keystone_authtoken project_name service
        ops_edit $com_neutron_conf keystone_authtoken username neutron
        ops_edit $com_neutron_conf keystone_authtoken password $NEUTRON_PASS
        
        ops_edit $com_neutron_conf oslo_concurrency lock_path /var/lib/neutron/tmp
        
        ops_edit $com_linuxbridge_agent linux_bridge physical_interface_mappings provider:ens256
        ops_edit $com_linuxbridge_agent vxlan enable_vxlan true
        ops_edit $com_linuxbridge_agent vxlan local_ip $LOCAL_IP
        ops_edit $com_linuxbridge_agent vxlan l2_population true
        ops_edit $com_linuxbridge_agent securitygroup enable_security_group True
        ops_edit $com_linuxbridge_agent securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
        
}

function com_neutron_restart {
        systemctl restart openstack-nova-compute.service

        systemctl enable neutron-linuxbridge-agent.service
        
        systemctl start neutron-linuxbridge-agent.service
       
}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################


echocolor "Install dich vu NEUTRON"
sleep 3
com_neutron_install

echocolor "Config dich vu NEUTRON"
sleep 3
com_neutron_config

echocolor "Restart dich vu NEUTRON"
sleep 3
com_neutron_restart