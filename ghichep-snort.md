# Ghi chép về snort

## Cài đặt Snort
### Chuẩn bị

#### Máy chủ

- OS: Ubuntu 14.04 64 bit

- eth0: EXT
    - IP: 
    - Netmask:
    
- eth1: MGNT 
    - IP:
    - Netmask:
    - Gateway:
    - DNS: 

#### Snort 
    
- snort-2.9.8.0.tar.gz

### Các bước cài đặt

#### Update các OS

- Đăng nhập với quyền root và thực hiện update hệ điều hành

    ```sh
    apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && init 6
    ```


- Cài đặt các gói bổ trợ

    ```sh 
    sudo apt-get install -y build-essential libpcap-dev libpcre3-dev libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl libssl-dev ethtool
    ```

#### Cấu hình interface 

- Disable LRO and GRO
- Mở file  `/etc/network/interfaces` và thêm các dòng dưới

    ```sh
    post-up ethtool -K eth0 gro off
    post-up ethtool -K eth0 lro off
    ```

    - Nội dung của file `/etc/network/interfaces`

        ```sh
        cat /etc/network/interfaces
        ```

    - Kết quả của lệnh cat 
            
        ```sh
        # This file describes the network interfaces available on your system
        # and how to activate them. For more information, see interfaces(5).
        source /etc/network/interfaces.d/*
         
        # The loopback network interface
        auto lo
        iface lo inet loopback
         
        # The primary network interface
        auto eth0
        iface eth0 inet dhcp
        post-up ethtool -K eth0 gro off
        post-up ethtool -K eth0 lro off
        ```
        
- Khởi động lại máy chủ

    ```sh
    init 6
    ``` 

- Xác nhận lại kết quả sau khi disbale GRO và LRO

    ```sh
    ethtool -k eth0 | grep receive-offload
    ```

    - Kết quả: 

        ```sh
        root@uvdc:~# ethtool -k eth0 | grep receive-offload
        generic-receive-offload: off
        large-receive-offload: off [fixed]
        root@uvdc:~#
        ```
        
#### Cài đặt snort

- Tạo thư mục để cài đặt Snort

    ```sh
    mkdir ~/snort_src
    cd ~/snort_src
    ```
    
- Tài và cài đặt thư việc DAQ

    ```sh
    cd ~/snort_src
    wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
    tar -xvzf daq-2.0.6.tar.gz
    cd daq-2.0.6
    ./configure
    make
    sudo make install
    ```
    
- Tải và cài đặt Snort

    ```sh
    cd ~/snort_src
    wget https://snort.org/downloads/snort/snort-2.9.8.0.tar.gz
    tar -xvzf snort-2.9.8.0.tar.gz
    cd snort-2.9.8.0
    ./configure --enable-sourcefire
    make
    sudo make install
    ```
    
- Update thư viện

    ```sh
    sudo ldconfig
    ```
    
- Tạo link cho thư mục của snort

    ```sh
    sudo ln -s /usr/local/bin/snort /usr/sbin/snort
    ```

- Kiểm tra phiên bản của snort vừa cài

    ```sh
    snort -V
    ```

    - Kết quả 

        ```ssh

        ```
        
- 