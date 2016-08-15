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
    sudo apt-get install -y build-essential libpcap-dev libpcre3-dev \
        libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl libssl-dev ethtool tree
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
        
- Khởi động card mạng của máy chủ

    ```sh
    ifdown -a && ifup -a
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
    wget https://www.snort.org/downloads/snort/snort-2.9.8.3.tar.gz
    tar -xvzf snort-2.9.8.3.tar.gz
    cd snort-2.9.8.3
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
        root@uvdc:~/snort_src/snort-2.9.8.3# snort -V

           ,,_     -*> Snort! <*-
          o"  )~   Version 2.9.8.3 GRE (Build 383)
           ''''    By Martin Roesch & The Snort Team: http://www.snort.org/contact#team
                   Copyright (C) 2014-2015 Cisco and/or its affiliates. All rights reserved.
                   Copyright (C) 1998-2013 Sourcefire, Inc., et al.
                   Using libpcap version 1.5.3
                   Using PCRE version: 8.31 2012-07-06
                   Using ZLIB version: 1.2.8

        root@uvdc:~/snort_src/snort-2.9.8.3#
        root@uvdc:~/snort_src/snort-2.9.8.3#
        root@uvdc:~/snort_src/snort-2.9.8.3#
        ```
                
## Cấu hình Snort với mode IDS

### Tạo user `snort`
- Vì lý do an toàn, tạo user `snort` với quyền user thường

    ```sh
    sudo groupadd snort
    sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort
    ```

### Tạo các thư mục cho snort

    ```sh
    # Create the Snort directories:
    sudo mkdir /etc/snort
    sudo mkdir /etc/snort/rules
    sudo mkdir /etc/snort/rules/iplists
    sudo mkdir /etc/snort/preproc_rules
    sudo mkdir /usr/local/lib/snort_dynamicrules
    sudo mkdir /etc/snort/so_rules
     
    # Create some files that stores rules and ip lists
    sudo touch /etc/snort/rules/iplists/black_list.rules
    sudo touch /etc/snort/rules/iplists/white_list.rules
    sudo touch /etc/snort/rules/local.rules
    sudo touch /etc/snort/sid-msg.map
     
    # Create our logging directories:
    sudo mkdir /var/log/snort
    sudo mkdir /var/log/snort/archived_logs
     
    # Adjust permissions:
    sudo chmod -R 5775 /etc/snort
    sudo chmod -R 5775 /var/log/snort
    sudo chmod -R 5775 /var/log/snort/archived_logs
    sudo chmod -R 5775 /etc/snort/so_rules
    sudo chmod -R 5775 /usr/local/lib/snort_dynamicrules
     
    # Change Ownership on folders:
    sudo chown -R snort:snort /etc/snort
    sudo chown -R snort:snort /var/log/snort
    sudo chown -R snort:snort /usr/local/lib/snort_dynamicrules
    ```

- Copy các file vào thư mục `/etc/snort` vừa tạo ở bên trên

    ```sh
    cd ~/snort_src/snort-2.9.8.3/etc/
    sudo cp *.conf* /etc/snort
    sudo cp *.map /etc/snort
    sudo cp *.dtd /etc/snort
     
    cd ~/snort_src/snort-2.9.8.3/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/
    sudo cp * /usr/local/lib/snort_dynamicpreprocessor/
    ```

- Kiểm tra các file vừa copy vào `/etc/snort`

    ```sh
    root@uvdc:~# tree /etc/snort/
    /etc/snort/
    ├── attribute_table.dtd
    ├── classification.config
    ├── file_magic.conf
    ├── gen-msg.map
    ├── preproc_rules
    ├── reference.config
    ├── rules
    │   ├── iplists
    │   │   ├── black_list.rules
    │   │   └── white_list.rules
    │   └── local.rules
    ├── sid-msg.map
    ├── snort.conf
    ├── so_rules
    ├── threshold.conf
    └── unicode.map

    4 directories, 12 files
    ```

### Sửa file `/etc/snort/snort.conf`

- Sao lưu file `/etc/snort/snort.conf`
    
    ```sh
    cp /etc/snort/snort.conf /etc/snort/snort.conf.orig
    ```
    
- Bỏ comment các dòng từ 547 tới 651 (các dòng bắt đầu là `include $RULE_PATH`) bằng lệnh dưới.
    
    ```sh
    sudo sed -i 's/include \$RULE\_PATH/#include \$RULE\_PATH/' /etc/snort/snort.conf
    ```
  
- Sửa file `/etc/snort/snort.conf` bằng lệnh vi

    ```sh
    sudo vi /etc/snort/snort.conf
    ```

    - Sửa dòng 45 `ipvar HOME_NET any` như sau (IP của dải internal):

        ```sh
        ipvar HOME_NET 10.10.10.0/24
        ```
    - Sửa dòng 48 `ipvar EXTERNAL_NET any` như sau (IP của dải external)
    
        ```sh
        ipvar EXTERNAL_NET any
        ```
    - Sửa các dòng dưới như sau
    
        ```sh
        var RULE_PATH /etc/snort/rules                      # line 104
        var SO_RULE_PATH /etc/snort/so_rules                # line 105
        var PREPROC_RULE_PATH /etc/snort/preproc_rules      # line 106

        var WHITE_LIST_PATH /etc/snort/rules/iplists        # line 113
        var BLACK_LIST_PATH /etc/snort/rules/iplists        # line 114
        ```

    - Nếu muốn include các rule trong `/etc/snort/rules/local.rules` thì bỏ comment dòng 545, thành như sau:    
    
        ```sh
        include $RULE_PATH/local.rules
        ```

### Kiểm tra lại cấu hình của snort sau khi sửa

- Thưc thi lệnh dưới

    ```sh
    sudo snort -T -c /etc/snort/snort.conf -i eth0
    ```
    
    - Trong đó:    
    
        - `-T`: là chế độ test.
        - `-c`: chỉ ra đường dẫn file cấu hình.
        - `-i`: Interface mà snort sẽ lắng nghe.

- Kết quả như dưới là OK

    ```sh
    Acquiring network traffic from "eth0".

            --== Initialization Complete ==--

       ,,_     -*> Snort! <*-
      o"  )~   Version 2.9.8.3 GRE (Build 383)
       ''''    By Martin Roesch & The Snort Team: http://www.snort.org/contact#team
               Copyright (C) 2014-2015 Cisco and/or its affiliates. All rights reserved.
               Copyright (C) 1998-2013 Sourcefire, Inc., et al.
               Using libpcap version 1.5.3
               Using PCRE version: 8.31 2012-07-06
               Using ZLIB version: 1.2.8

               Rules Engine: SF_SNORT_DETECTION_ENGINE  Version 2.6  <Build 1>
               Preprocessor Object: SF_IMAP  Version 1.0  <Build 1>
               Preprocessor Object: SF_SSH  Version 1.1  <Build 3>
               Preprocessor Object: SF_MODBUS  Version 1.1  <Build 1>
               Preprocessor Object: SF_SIP  Version 1.1  <Build 1>
               Preprocessor Object: SF_DNS  Version 1.1  <Build 4>
               Preprocessor Object: SF_SDF  Version 1.1  <Build 1>
               Preprocessor Object: SF_GTP  Version 1.1  <Build 1>
               Preprocessor Object: SF_SSLPP  Version 1.1  <Build 4>
               Preprocessor Object: SF_FTPTELNET  Version 1.2  <Build 13>
               Preprocessor Object: SF_DCERPC2  Version 1.0  <Build 3>
               Preprocessor Object: SF_SMTP  Version 1.1  <Build 9>
               Preprocessor Object: SF_DNP3  Version 1.1  <Build 1>
               Preprocessor Object: SF_REPUTATION  Version 1.1  <Build 1>
               Preprocessor Object: SF_POP  Version 1.0  <Build 1>

    Snort successfully validated the configuration!
    Snort exiting

    ```
    
## Tham khảo: 

- http://sublimerobots.com/2015/12/snort-2-9-8-x-on-ubuntu-part-1/
- 