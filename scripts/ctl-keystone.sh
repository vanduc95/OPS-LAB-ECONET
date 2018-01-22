#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

### Khai bao bien de thuc hien

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

function create_keystone_db {
mysql -uroot -p$PASS_DATABASE_ROOT -h $DB1_IP_NIC2 -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$PASS_DATABASE_KEYSTONE';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$PASS_DATABASE_KEYSTONE';
FLUSH PRIVILEGES;"
}

function keystone_install {
        for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
        do
            ssh root@$IP_ADD "yum -y install openstack-keystone httpd mod_wsgi"
        done       
}

function keystone_config {
        keystone_conf=/etc/keystone/keystone.conf
        cp $keystone_conf $keystone_conf.orig        
        ops_edit $keystone_conf database connection mysql+pymysql://keystone:$PASS_DATABASE_KEYSTONE@$IP_VIP_DB/keystone
        ops_edit $keystone_conf token provider fernet
}
function keystone_syncdb {
          su -s /bin/sh -c "keystone-manage db_sync" keystone
          keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
          keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
          for IP_ADD in $CTL2_IP_NIC3 $CTL3_IP_NIC3
          do  
            echocolor "Copy file cau hinh, credential-keys va fernet-keys cho $IP_ADD"
            scp $keystone_conf root@$IP_ADD:/etc/keystone/
            scp -r /etc/keystone/credential-keys root@$IP_ADD:/etc/keystone/
            scp -r /etc/keystone/fernet-keys root@$IP_ADD:/etc/keystone/
            ssh root@$IP_ADD "chown -R keystone:keystone /etc/keystone/credential-keys/"
            ssh root@$IP_ADD "chown -R keystone:keystone /etc/keystone/fernet-keys/"
          done
}

function keystone_bootstrap {
          keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
          --bootstrap-admin-url http://$IP_VIP_API:35357/v3/ \
          --bootstrap-internal-url http://$IP_VIP_API:5000/v3/ \
          --bootstrap-public-url http://$IP_VIP_API:5000/v3/ \
          --bootstrap-region-id RegionOne
}

function keystone_config_http {
          echo "ServerName `hostname`" >> /etc/httpd/conf/httpd.conf
          ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
          systemctl enable httpd.service
          systemctl start httpd.service 
}

function keystone_endpoint {
        openstack project create service --domain default --description "Service Project" 
        openstack project create demo --domain default --description "Demo Project" 
        openstack user create demo --domain default --password $DEMO_PASS
        openstack role create user
        openstack role add --project demo --user demo user

}

function keystone_create_adminrc {
cat << EOF > /root/admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$IP_VIP_API:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

EOF

sleep 5
echocolor "Execute environment script"
chmod +x admin-openrc
cat  admin-openrc >> /etc/profile
source admin-openrc


cat << EOF > /root/demo-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$IP_VIP_API:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

EOF
chmod +x demo-openrc
}

###########################
# Thuc thi cac functions
# Goi cac functions
###########################
echocolor "Cai dat Keystone"
sleep 3

echocolor "Tao DB keystone"
sleep 3
create_keystone_db

echocolor "Cai dat keystone"
sleep 3
keystone_install

echocolor "Config keystone"
sleep 3
keystone_config

echocolor "Sync DB cho keystone"
sleep 3
keystone_syncdb

echocolor "Tao endpoint"
sleep 3
keystone_bootstrap

echocolor "Cau hinh http"
sleep 3
for IP_ADD in $CTL1_IP_NIC3 $CTL2_IP_NIC3 $CTL3_IP_NIC3
do
    echo "Cai dat keystone_config_http $IP_ADD"
    ssh root@$IP_ADD "$(typeset -f); keystone_config_http"
done

echocolor "Tao bien moi truong"
sleep 3
keystone_create_adminrc
source admin-openrc

echocolor "Tao Endpoint"
sleep 3
keystone_endpoint