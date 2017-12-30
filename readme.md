# Hướng dẫn thực hiện
# MỤC LỤC 

1. Cài đặt trên các máy chủ LB
2. Cài đặt trên các máy chủ RABBITMQ
3. Cài đặt trên các máy chủ DATABASE
4. Cài đặt trên các máy chủ CONTROLLER
5. Cài đặt trên các máy chủ CEILOMETER


### Môi trường lab
- OS: Centos Minimal 7.4 - 64 bit

### Mô hình
![Topo-chieungang_v1.4_IP_Planning.png](../images/Topo-chieungang_v1.4_IP_Planning.png)

### IP Planning

![ip_planning_lb.png](../images/ip_planning_lb.png)

![ip_planning_mq.png](../images/ip_planning_mq.png)

![ip_planning_db.png](../images/ip_planning_db.png)

![ip_planning_ctl.png](../images/ip_planning_ctl.png)

![ip_planning_ceph.png](../images/ip_planning_ceph.png)

![ip_planning_cei.png](../images/ip_planning_cei.png)


## 1. Cài đặt trên các node LoadBalancer (Pacemaker, Corosync, Nginx)

### 1.1. Thực hiện script cài đặt pacemaker, corosync, cấu hình cluster

- Đứng trên máy chủ `lb1`, thực hiện script sau. Kết thúc script thì cả 2 node sẽ được cài đặt pacemaker, corosync và cấu hình cluster. 
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/lb-install.sh
    bash lb-install.sh
    ```
  
- Sau khi cấu hình cluster xong, thực hiện add resources cho pacemaker
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/lb-add-resources.sh
    bash lb-add-resources.sh
    ```
- Sau khi cài đặt LB xong, thực hiện lệnh `crm_mon -1` xem cụm LB đã ok hay chưa, kết quả như ảnh này là ok: http://prntscr.com/fxz09n (các resources cùng trên 1 node, nếu chưa nằm trên 1 node thì khởi động lại 1 node bất kỳ trong 02 node và kiểm tra lại)


- Tải file `nginx.conf` về để khai báo backend cho các dịch vụ sau này. Tải về cả 02 máy LB nhé ;).

    ```sh
    wget -O /ect/nginx/nginx.conf https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/conf/nginx.conf
    ```

- Lưu ý: nếu IP của các node Controller và DB thay đổi theo mô hình của bạn, thì cần sửa trong file nginx.conf sau khi tải về.

- Khởi động lại lần lượt 2 node LB và kiểm tra lại bằng lệnh `crm_mon -1`


## 2. Cài đặt trên các node Controller

### 2.1. Thực hiện script cài đặt cluster cho DATABASE
- Đăng nhập vào máy chủ `ctl1` và thưc hiện script sau, trong quá trình cài cần nhập mật khẩu root của 03 máy controller
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.

    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/db-install.sh
    bash db-install.sh
    ```
 
- Sau khi cài đặt xong, đứng ở 1 node CTL bất kỳ và thực hiện lệnh ở ảnh để kiểm tra DB Cluster đã hoạt động ok hay chưa: http://prntscr.com/fxyzsf

### 2.2. Thực hiện cài đặt cluster cho RABBITMQ
- Đứng trên node `ctl1` và thực hiện script sau.
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.

    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/rabbitmq-install.sh
    bash rabbitmq-install.sh
    ```
  
- Sau khi cài đặt xong, kiểm tra hoạt động của cluster bằng lệnh `rabbitmqctl cluster_staus`. Kết quả như ảnh này là ok:   http://prntscr.com/fxyzmf

  
### 2.3. Thực hiện cài đặt các gói chuẩn bị.
- Đứng trên node `ctl1` và thực hiện script sau.
- Lưu ý: Nếu các IP của bạn khác với các IP Planning thì cần sửa script trước khi thực hiện.

    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-prepare.sh
    bash ctl-prepare.sh
    ```

### 2.4. Thực hiện cài đặt keystone 
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-keystone.sh
    bash ctl-keystone.sh
    ```

### 2.5. Thực hiện cài đặt Glance 
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-glance.sh
    bash ctl-glance.sh
    ```

### 2.6. Thực hiện cài đặt Nova
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-nova.sh
    bash ctl-nova.sh
    ```

### 2.7. Thực hiện cài đặt Neutron
- Bước này thực hiện trên máy chủ `ctl1` 
- Tải script cài đặt keystone 
- Script tự động thực hiện cài đặt từ xa trên `ctl2` và `ctl3`

    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```
  
## 3. Cài đặt trên các node Network

### Thực hiện trên Network1
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-prepare.sh
    bash ctl-prepare.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```

### Thực hiện trên Network2
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-prepare.sh
    bash ctl-prepare.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```

## 4. Cài đặt trên các node Compute

### Thực hiện trên Compute1
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-prepare.sh
    bash ctl-prepare.sh
    ```

- Thực hiện cài đặt nova
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```


### Thực hiện trên Compute2
- Thực hiện cài đặt các gói chuẩn bị
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-prepare.sh
    bash ctl-prepare.sh
    ```

- Thực hiện cài đặt nova
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```

- Thực hiện cài đặt neutron
    ```sh
    curl -O https://raw.githubusercontent.com/congto/openstack-HA/master/scripts/ctl-neutron.sh
    bash ctl-neutron.sh
    ```
    
#### Kiểm tra

- Chuyển qua Controller, kiểm tra các dịch vụ neutron và nova

    ```sh
    openstack compute service list

    neutron agent-list 
    ```


### Mở rule,tạo mạng, tạo máy ảo:

- Mở các rule (cần kiểm tra lại các rule xem có bị trùng hay không, vì trong quá trình lab với HA có hiện tượng trùng các rule)
    ```sh
    openstack security group rule create --proto icmp default
    openstack security group rule create --proto tcp --dst-port 22 default
    ```
    
- Tạo flavor

    ```sh
    openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
    ```
    
- Tạo network (không sửa tên các tùy chọn ở đây vì đã đúng với cấu hình trước đó khi cài neutron và nova)


    ```sh 
    openstack network create  --share --external \
        --provider-physical-network provider \
        --provider-network-type flat provider
    ```  
        
- Lưu ý: ghi IP của network ở trên lại để dùng khi tạo máy ảo ở bên dưới. ID_CUA_NETWORK

- Tạo subnet. Cần thay đổi dải IP cho phù hợp với hệ thống của bạn (các IP mà bạn được cấp)/. Gateway và DNS để nguyên

    ```
    openstack subnet create --network provider \
        --allocation-pool start=192.168.40.190,end=192.168.40.210 \
        --dns-nameserver 8.8.8.8 --gateway 192.168.40.254 \
        --subnet-range 192.168.40.0/24 provider
    ```
    
- Tạo máy ảo

```
openstack server create  vm03 --flavor m1.nano --image cirros \
  --nic net-id=ID_CUA_NETWORK --security-group default 
````

- Kiểm tra trạng thái máy ảo sau khi tạo
```
openstack server list
```

- Ping tới IP máy ảo được cấp.

