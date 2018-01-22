#!/bin/bash -ex
### Script cai dat rabbitmq tren mq1
# Khai bao bien cho cac script 
cat <<EOF> /root/db-config.cfg
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

### Password cho MariaDB
PASS_DATABASE_ROOT='Ec0net2017'
PASS_DATABASE_KEYSTONE=\$PASS_DATABASE_ROOT
PASS_DATABASE_NOVA=\$PASS_DATABASE_ROOT
PASS_DATABASE_NOVA_API=\$PASS_DATABASE_ROOT
PASS_DATABASE_NEUTRON=\$PASS_DATABASE_ROOT
PASS_DATABASE_GLANCE=\$PASS_DATABASE_ROOT
PASS_DATABASE_CEILOMTER=\$PASS_DATABASE_ROOT
PASS_DATABASE_AODH=\$PASS_DATABASE_ROOT
PASS_DATABASE_GNOCCHI=\$PASS_DATABASE_ROOT

EOF

source db-config.cfg 

function setup_config {
        for IP_ADD in $DB1_IP_NIC2 $DB2_IP_NIC2 $DB3_IP_NIC2
        do
                scp /root/db-config.cfg root@$IP_ADD:/root/
                chmod +x db-config.cfg 
        done
}


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


function copykey() {
        ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
        for IP_ADD in $DB1_IP_NIC2 $DB2_IP_NIC2 $DB3_IP_NIC2
        do
                ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$IP_ADD
        done
}


function install_repo_galera {
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo

yum -y upgrade
}


function khai_bao_host {
        source db-config.cfg
        echo "$DB1_IP_NIC2 db1" >> /etc/hosts
        echo "$DB2_IP_NIC2 db2" >> /etc/hosts
        echo "$DB3_IP_NIC2 db3" >> /etc/hosts
        scp /etc/hosts root@$DB2_IP_NIC2:/etc/
        scp /etc/hosts root@$DB3_IP_NIC2:/etc/
}


function install_mariadb_galera {
        source db-config.cfg
        IP_ADD_MNGT=`ip -o -4 addr show dev ens192 | sed 's/.* inet \([^/]*\).*/\1/'| head -n 1`
        HOSTNAME_DB=`hostname`
        yum -y install mariadb mariadb-server python2-PyMySQL rsync xinetd crudini vim
        
cat << EOF > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF
       cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/server.cnf.orig
       
cat <<EOF > /etc/my.cnf.d/server.cnf
[server]
[mysqld]
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://$DB1_IP_NIC2,$DB2_IP_NIC2,$DB3_IP_NIC2"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
wsrep_cluster_name="linoxide_cluster"
bind-address=0.0.0.0
wsrep_node_address="$IP_ADD_MNGT"
wsrep_node_name="$HOSTNAME_DB"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.1]
EOF
             
}


function set_pass_db {
        source db-config.cfg
        HOSTNAME_DB=`hostname`
        PASS_DATABASE_ROOT=Ec0net2017
cat << EOF | mysql -uroot
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$PASS_DATABASE_ROOT';FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$PASS_DATABASE_ROOT';FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.20.71' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.20.72' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.20.73' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '$PASS_DATABASE_ROOT';FLUSH PRIVILEGES;
EOF
}


function restart_db {
        systemctl enable mariadb.service
        systemctl start mariadb.service
}


############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Cai dat MariaDB, Galera"
sleep 3

echocolor "Tao key va copy key, bien khai bao sang cac node"
sleep 3
copykey
setup_config


echocolor " install_repo "
sleep 3
for IP_ADD in $DB1_IP_NIC2 $DB2_IP_NIC2 $DB3_IP_NIC2
do 

    echocolor "Cai dat install_repo tren $IP_ADD"
    sleep 3
    ssh root@$IP_ADD "$(typeset -f); install_repo_galera"
    
    if [ "$IP_ADD" == "$DB1_IP_NIC2" ]; then
      echocolor "Cai dat khai_bao_host tren $IP_ADD"
      sleep 3
      ssh root@$IP_ADD "$(typeset -f); khai_bao_host"
    fi 
done 


echocolor " Cai dat MariaDB galera "
sleep 3
for IP_ADD in $DB1_IP_NIC2 $DB2_IP_NIC2 $DB3_IP_NIC2
do 
    echocolor "Cai dat install_mariadb_galera tren $IP_ADD"
    sleep 3
    ssh root@$IP_ADD "$(typeset -f); install_mariadb_galera"   
done 


echocolor "Khoi dong MariaDB Cluster "
sleep 3

for IP_ADD in $DB1_IP_NIC2 $DB2_IP_NIC2 $DB3_IP_NIC2
do 
    if [ "$IP_ADD" == "$DB1_IP_NIC2" ]; then
      echocolor "Thuc hien khoi dong cluster DB $IP_ADD"
       sleep 3
       galera_new_cluster
    else 
      echocolor "Thuc hien khoi dong tren $IP_ADD"
      ssh root@$IP_ADD "$(typeset -f); restart_db"    
     fi
done 


echocolor "Dat mat khau cho DB MariaDB Cluster "
sleep 3
set_pass_db

echocolor "DONE"
