﻿
### Môi trường lab
- OS: Centos Minimal 7.4 - 64 bit

### Mô hình
- 2 LoadBalancer, 3 Controller, 2 Network, 2 Compute
- Database và RabbitMQ Cluster được cài đặt trên các node Controller.

### IP Planning

![ip_planning_lb.png](img/ip_planning_lb.png)

![ip_planning_ctl.png](img/ip_planning_ctl.png)

![ip_planning_net.png](img/ip_planning_net.png)

![ip_planning_com.png](img/ip_planning_com.png)


## 1. Cài đặt trên các node LoadBalancer (Pacemaker, Corosync, Nginx)

### 1.1. Thực hiện script cài đặt pacemaker, corosync, cấu hình cluster

- Đứng trên máy chủ `lb1`, thực hiện script sau. Kết thúc script thì cả 2 node sẽ được cài đặt pacemaker, corosync và cấu hình cluster. Trong quá trình cài cần nhập mật khẩu root của 02 máy loadbalancer
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/lb-install.sh
    bash lb-install.sh
    ```
  
- Sau khi cấu hình cluster xong, thực hiện add resources cho pacemaker
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/lb-add-resources.sh
    bash lb-add-resources.sh
    ```
- Sau khi cài đặt LB xong, thực hiện kiểm tra bằng lệnh sau, các resource cần cùng nằm trên 1 node lb1 hoặc lb2.
    ```sh
    [root@lb1 ~]# pcs status
    Cluster name: ha_cluster
    Stack: corosync
    Current DC: lb2 (version 1.1.16-12.el7_4.5-94ff4df) - partition with quorum
    Last updated: Tue Jan  2 16:47:53 2018
    Last change: Tue Jan  2 16:26:45 2018 by root via cibadmin on lb1

    2 nodes configured
    3 resources configured

    Online: [ lb1 lb2 ]

    Full list of resources:

     Virtual_IP_API (ocf::heartbeat:IPaddr2):       Started lb1
     Virtual_IP_DB  (ocf::heartbeat:IPaddr2):       Started lb1
     Web_Cluster    (ocf::heartbeat:nginx): Started lb1

    Daemon Status:
      corosync: active/enabled
      pacemaker: active/enabled
      pcsd: active/enabled

    ```


- Tải file `nginx.conf` về để khai báo backend cho các dịch vụ sau này. Tải về cả 02 máy LB và copy trong thư mục `/etc/nginx/nginx.conf`

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/nginx.conf

    cp nginx.conf /etc/nginx/nginx.conf
    ```

- Lưu ý: nếu IP của các node Controller và DB thay đổi theo mô hình của bạn, thì cần sửa trong file nginx.conf sau khi tải về.

- Khởi động lại lần lượt 2 node LB và kiểm tra lại bằng lệnh `pcs status`


## 2. Cài đặt trên các node Controller

### 2.1. Thực hiện script cài đặt cluster cho DATABASE
- Đăng nhập vào máy chủ `ctl1` và thưc hiện script sau, trong quá trình cài cần nhập mật khẩu root của 03 máy controller
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/db-install.sh
    bash db-install.sh
    ```
 
- Sau khi cài đặt xong, đứng ở 1 node CTL bất kỳ và thực hiện lệnh sau để kiểm tra hoạt động của DB cluster.

    ```
    [root@ctl1 ~]# mysql -u root -p'Ec0net2017' -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
    +--------------------+-------+
    | Variable_name      | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 3     |
    +--------------------+-------+
    
    ```

### 2.2. Thực hiện cài đặt cluster cho RABBITMQ
- Đứng trên node `ctl1` và thực hiện script sau.
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/rabbitmq-install.sh
    bash rabbitmq-install.sh
    ```
  
- Sau khi cài đặt xong, kiểm tra hoạt động của cluster bằng lệnh sau: 

    ```
    [root@ctl1 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@ctl1 ...
    [{nodes,[{disc,[rabbit@ctl1,rabbit@ctl2,rabbit@ctl3]}]},
     {running_nodes,[rabbit@ctl3,rabbit@ctl2,rabbit@ctl1]},
     {cluster_name,<<"rabbit@ctl2">>},
     {partitions,[]},
     {alarms,[{rabbit@ctl3,[]},{rabbit@ctl2,[]},{rabbit@ctl1,[]}]}]
    
    ```
  
### 2.3. Thực hiện cài đặt các gói chuẩn bị.
- Đứng trên node `ctl1` và thực hiện script sau.
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/ctl-prepare.sh
    bash ctl-prepare.sh
    ```

### 2.4. Thực hiện cài đặt keystone 
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/ctl-keystone.sh
    bash ctl-keystone.sh
    ```
- Verify keystone

    ```
    [root@ctl1 ~]# openstack token issue
    +------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Field      | Value                                                                                                                                                                                   |
    +------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | expires    | 2018-01-02T08:19:09+0000                                                                                                                                                                |
    | id         | gAAAAABaSzJtYsQLesZIM0T6efTooyAmqEdr5QHPTHOR6WugrAGAWLKrLJZYffxugzh-h5MRv1j8KAub-cJxhlAwZynrLmjKxRE7qIZMaKpVS42kfD7jBEmWnYmQEhqyRWXk8j6l2wBB1NOpn4lM000J7wd5nMXuyPQHj2YF9OwsybWw05zIUTA |
    | project_id | a9746af0785f484cb66088646a3b3b4f                                                                                                                                                        |
    | user_id    | 56d069919d8442c5985102758df98870                                                                                                                                                        |
    +------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    
    ```

### 2.5. Thực hiện cài đặt Glance 
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/ctl-glance.sh
    bash ctl-glance.sh
    ```
- Verify Glance

    ```
    [root@ctl1 ~]# openstack image list
    +--------------------------------------+--------+--------+
    | ID                                   | Name   | Status |
    +--------------------------------------+--------+--------+
    | 667f5f89-710c-4197-8a55-a84ae942e359 | cirros | active |
    +--------------------------------------+--------+--------+
    
    ```

### 2.6. Thực hiện cài đặt Nova
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/ctl-nova.sh
    bash ctl-nova.sh
    ```

### 2.7. Thực hiện cài đặt Neutron
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```
  
## 3. Cài đặt trên các node Network

### 3.1. Thực hiện trên Network1
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/net-prepare.sh
    bash net-prepare.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/net-neutron.sh
    bash net-neutron.sh
    ```

### 3.2. Thực hiện trên Network2
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/net-prepare.sh
    bash net-prepare.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/net-prepare.sh
    bash net-prepare.sh
    ```

## 4. Cài đặt trên các node Compute

### 4.1. Thực hiện trên Compute1
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/com-prepare.sh
    bash com-prepare.sh
    ```

- Thực hiện cài đặt nova
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/com-nova.sh
    bash com-nova.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/com-neutron.sh
    bash com-neutron.sh
    ```


### 4.2. Thực hiện trên Compute2
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/com-prepare.sh
    bash com-prepare.sh
    ```

- Thực hiện cài đặt nova
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/com-nova.sh
    bash com-nova.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -Ok https://git.econet.vn/projects/OP/repos/openstack-pike-ha-centos/raw/scripts/com-neutron.sh
    bash com-neutron.sh
    ```
    
## 5. Kiểm tra

- Sau khi thực hiện cài đặt nova và neutron trên các node Controller, Network, và Compute, chuyển qua Controller, verify dịch vụ nova và neutron.
- Verify nova

    ```
    [root@ctl1 ~]# openstack compute service list
    +----+------------------+------+----------+---------+-------+----------------------------+
    | ID | Binary           | Host | Zone     | Status  | State | Updated At                 |
    +----+------------------+------+----------+---------+-------+----------------------------+
    | 16 | nova-consoleauth | ctl1 | internal | enabled | up    | 2018-01-02T07:34:34.000000 |
    | 19 | nova-scheduler   | ctl1 | internal | enabled | up    | 2018-01-02T07:34:31.000000 |
    | 22 | nova-conductor   | ctl1 | internal | enabled | up    | 2018-01-02T07:34:37.000000 |
    | 46 | nova-consoleauth | ctl2 | internal | enabled | up    | 2018-01-02T07:34:32.000000 |
    | 49 | nova-scheduler   | ctl2 | internal | enabled | up    | 2018-01-02T07:34:36.000000 |
    | 52 | nova-conductor   | ctl2 | internal | enabled | up    | 2018-01-02T07:34:34.000000 |
    | 67 | nova-consoleauth | ctl3 | internal | enabled | up    | 2018-01-02T07:34:28.000000 |
    | 70 | nova-scheduler   | ctl3 | internal | enabled | up    | 2018-01-02T07:34:36.000000 |
    | 73 | nova-conductor   | ctl3 | internal | enabled | up    | 2018-01-02T07:34:34.000000 |
    | 82 | nova-compute     | com1 | nova     | enabled | up    | 2018-01-02T07:34:34.000000 |
    | 85 | nova-compute     | com2 | nova     | enabled | up    | 2018-01-02T07:34:35.000000 |
    +----+------------------+------+----------+---------+-------+----------------------------+
    
    [root@ctl1 ~]# openstack hypervisor list
    +----+---------------------+-----------------+---------------+-------+
    | ID | Hypervisor Hostname | Hypervisor Type | Host IP       | State |
    +----+---------------------+-----------------+---------------+-------+
    |  4 | com1                | QEMU            | 192.168.20.81 | up    |
    |  7 | com2                | QEMU            | 192.168.20.82 | up    |
    +----+---------------------+-----------------+---------------+-------+
    
    ```
- Verify neutron

    ```
    [root@ctl1 ~]# openstack network agent list
    +--------------------------------------+--------------------+------+-------------------+-------+-------+---------------------------+
    | ID                                   | Agent Type         | Host | Availability Zone | Alive | State | Binary                    |
    +--------------------------------------+--------------------+------+-------------------+-------+-------+---------------------------+
    | 1f134a5f-0099-4cf2-bc19-212adc8a811b | Linux bridge agent | com1 | None              | :-)   | UP    | neutron-linuxbridge-agent |
    | 214b8630-88c8-4e0b-9798-67d5b9f32852 | L3 agent           | net1 | nova              | :-)   | UP    | neutron-l3-agent          |
    | 2e08a169-f2eb-4a87-917f-179dfb049cff | Metadata agent     | net1 | None              | :-)   | UP    | neutron-metadata-agent    |
    | 46f9f461-3293-4b8a-a778-0f310664a833 | Metadata agent     | net2 | None              | :-)   | UP    | neutron-metadata-agent    |
    | 4a03e8d3-f40e-490c-adab-541633992bbe | Linux bridge agent | net2 | None              | :-)   | UP    | neutron-linuxbridge-agent |
    | 4d0d2809-f67d-41c7-9ef5-54f487a0bd8b | DHCP agent         | net2 | nova              | :-)   | UP    | neutron-dhcp-agent        |
    | bcef788f-4f64-4617-865a-5ec5f09c3167 | DHCP agent         | net1 | nova              | :-)   | UP    | neutron-dhcp-agent        |
    | c36b306f-a781-4de7-b52b-82ee033d3b3a | Linux bridge agent | net1 | None              | :-)   | UP    | neutron-linuxbridge-agent |
    | ec69dd0e-ed73-40dc-ada3-289d8dc8b3db | L3 agent           | net2 | nova              | :-)   | UP    | neutron-l3-agent          |
    | fb28dc1b-a15e-48d6-b107-51915903b78e | Linux bridge agent | com2 | None              | :-)   | UP    | neutron-linuxbridge-agent |
    +--------------------------------------+--------------------+------+-------------------+-------+-------+---------------------------+
    
    ```


## 6. Tạo và khởi động máy ảo

- Tạo flavor

    ```
    openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
    ```

- Mở các security group rules

    ```
    openstack security group rule create --proto icmp default
    openstack security group rule create --proto tcp --dst-port 22 default
    ```

- Tạo network `provider`

    ```
    openstack network create  --share --external \
    --provider-physical-network provider \
    --provider-network-type flat provider
    
    
    openstack subnet create --network provider --allocation-pool start=192.168.50.100,end=192.168.50.210 --dns-nameserver 8.8.8.8 --gateway 192.168.50.254 --subnet-range 192.168.50.0/24 provider
    ```
  
- Tạo network `selfservice`

    ```
    openstack network create selfservice
    
    openstack subnet create --network selfservice \
      --dns-nameserver 8.8.8.8 --gateway 172.16.1.1 \
      --subnet-range 172.16.1.0/24 selfservice
    
    openstack router create router
    
    neutron router-interface-add router selfservice
    
    neutron router-gateway-set router provider
    
    ```

- Tạo máy ảo 

    ```
    openstack server create vm01 --flavor m1.nano --image cirros \
    --nic net-id=NET_ID --security-group SECURITY_ID 
    ```
    
Thay `NET_ID` bằng id của provider network hoặc selfservice network. Để lấy `NET_ID` và `SECURITY_ID` , sử dụng câu lệnh sau:

```
openstack network list
+--------------------------------------+-------------+--------------------------------------+
| ID                                   | Name        | Subnets                              |
+--------------------------------------+-------------+--------------------------------------+
| b77ffc7f-3b4e-44de-9355-1e848f103288 | provider    | 47252530-fbd9-44c6-879b-d51ce0f9ce51 |
| d04fba4b-bbe2-44d4-85af-c83dc5a60f14 | selfservice | a3aa438a-ffd6-4cce-bb11-71f8ff6c8dbd |
+--------------------------------------+-------------+--------------------------------------+

openstack security group list
+--------------------------------------+---------+------------------------+----------------------------------+
| ID                                   | Name    | Description            | Project                          |
+--------------------------------------+---------+------------------------+----------------------------------+
| 7cf8cc03-4000-4dc5-9d7e-e6a8059801d1 | default | Default security group | db25fdd692b8419791aeb92019b2c4fe |
| a1622c25-4b35-4d17-83ed-ec9acff7fc00 | default | Default security group | 043cf0ecc0b8462bb15dcc55b11df1a9 |
+--------------------------------------+---------+------------------------+----------------------------------+
```

- Kiểm tra trạng thái của máy ảo

    ```
    # openstack server list
    +--------------------------------------+--------+--------+----------------------------------------+--------+---------+
    | ID                                   | Name   | Status | Networks                               | Image  | Flavor  |
    +--------------------------------------+--------+--------+----------------------------------------+--------+---------+
    | ec1e8fa9-4314-411b-b045-87c6597f28e4 | vm02   | ACTIVE | selfservice=172.16.1.5, 192.168.50.107 | cirros | m1.nano |
    | bd69fc45-47aa-4ec4-944e-22ef2471bd5a | vm01   | ACTIVE | provider=192.168.50.109                | cirros | m1.nano |
    +--------------------------------------+--------+--------+----------------------------------------+--------+---------+
    
    ```

- Ping tới máy ảo được cấp

    ```
    # ping 192.168.50.109
    PING 192.168.50.109 (192.168.50.109) 56(84) bytes of data.
    64 bytes from 192.168.50.109: icmp_seq=1 ttl=63 time=3.89 ms
    64 bytes from 192.168.50.109: icmp_seq=2 ttl=63 time=1.56 ms
    64 bytes from 192.168.50.109: icmp_seq=3 ttl=63 time=1.01 ms
    ^C
    --- 192.168.50.109 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2002ms
    rtt min/avg/max/mdev = 1.014/2.158/3.895/1.249 ms
    ```
