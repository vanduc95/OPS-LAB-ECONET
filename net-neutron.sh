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


function net_neutron_install {
        yum install -y  openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables
}

function net_neutron_config {

        LOCAL_IP=`ip -o -4 addr show dev ens161 | sed 's/.* inet \([^/]*\).*/\1/'| head -n 1`

        net_neutron_conf=/etc/neutron/neutron.conf
        net_linuxbridge_agent=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
        net_dhcp_agent=/etc/neutron/dhcp_agent.ini
        net_metadata_agent=/etc/neutron/metadata_agent.ini
        net_l3_agent=/etc/neutron/l3_agent.ini
        
        cp $net_neutron_conf $net_neutron_conf.orig
        cp $net_linuxbridge_agent $net_linuxbridge_agent.orig
        cp $net_dhcp_agent $net_dhcp_agent.orig
        cp $net_metadata_agent $net_metadata_agent.orig
        cp $net_l3_agent $net_l3_agent.orig
        
        ops_edit $net_neutron_conf DEFAULT auth_strategy keystone
        ops_edit $net_neutron_conf DEFAULT core_plugin ml2
        ops_edit $net_neutron_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$MQ1_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ2_IP_NIC1:5672,openstack:$RABBIT_PASS@$MQ3_IP_NIC1:5672
        
        ops_edit $net_neutron_conf oslo_messaging_rabbit rabbit_ha_queues true
        ops_edit $net_neutron_conf oslo_messaging_rabbit rabbit_retry_interval 1
        ops_edit $net_neutron_conf oslo_messaging_rabbit rabbit_retry_backoff 2
        ops_edit $net_neutron_conf oslo_messaging_rabbit rabbit_durable_queues true
        
        ops_edit $net_neutron_conf keystone_authtoken auth_uri http://$IP_VIP_API:5000
        ops_edit $net_neutron_conf keystone_authtoken auth_url http://$IP_VIP_API:35357
        ops_edit $net_neutron_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211,$CTL2_IP_NIC1:11211,$CTL3_IP_NIC1:11211
        ops_edit $net_neutron_conf keystone_authtoken auth_type password
        ops_edit $net_neutron_conf keystone_authtoken project_domain_name Default
        ops_edit $net_neutron_conf keystone_authtoken user_domain_name Default
        ops_edit $net_neutron_conf keystone_authtoken project_name service
        ops_edit $net_neutron_conf keystone_authtoken username neutron
        ops_edit $net_neutron_conf keystone_authtoken password $NEUTRON_PASS
        
        ops_edit $net_neutron_conf oslo_concurrency lock_path /var/lib/neutron/tmp
        

        ops_edit $net_linuxbridge_agent linux_bridge physical_interface_mappings provider:ens224
        ops_edit $net_linuxbridge_agent vxlan enable_vxlan true
        ops_edit $net_linuxbridge_agent vxlan local_ip $LOCAL_IP
        ops_edit $net_linuxbridge_agent vxlan l2_population true
        ops_edit $net_linuxbridge_agent securitygroup enable_security_group True
        ops_edit $net_linuxbridge_agent securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
        

        ops_edit $net_l3_agent DEFAULT interface_driver linuxbridge

        
        ops_edit $net_dhcp_agent DEFAULT interface_driver linuxbridge
        ops_edit $net_dhcp_agent DEFAULT enable_isolated_metadata true
        ops_edit $net_dhcp_agent DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
        ops_edit $net_dhcp_agent DEFAULT force_metadata true


        ops_edit $net_metadata_agent DEFAULT nova_metadata_ip $IP_VIP_API
        ops_edit $net_metadata_agent DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
}

function net_neutron_restart {
        systemctl enable neutron-linuxbridge-agent.service
        systemctl enable neutron-metadata-agent.service
        systemctl enable neutron-dhcp-agent.service
        systemctl enable neutron-l3-agent.service
        
        systemctl start neutron-linuxbridge-agent.service
        systemctl start neutron-metadata-agent.service
        systemctl start neutron-dhcp-agent.service
        systemctl start neutron-l3-agent.service
       
}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################


echocolor "Install dich vu NEUTRON"
sleep 3
net_neutron_install

echocolor "Config dich vu NEUTRON"
sleep 3
net_neutron_config

echocolor "Restart dich vu NEUTRON"
sleep 3
net_neutron_restart