#!/usr/bin/env bash

# Copyright : ando@next-season.net
# Version: 0.1
# Support: Amazon Linux 2
# Original: https://github.com/losywee/rtmp-streaming-server-build-script/blob/master/build.sh


# Make Swap
# https://aws.amazon.com/jp/premiumsupport/knowledge-center/ec2-memory-swap-file/

dd if=/dev/zero of=/swapfile bs=128M count=32
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon -s
echo '/swapfile swap swap defaults 0 0' >>  /etc/fstab


# update

yum update -y
yum upgrade -y
yum -y install git gcc pcre-devel openssl-devel


#make nginx user
groupadd nginx
useradd -g nginx nginx
usermod -s /bin/false nginx
mkdir -p /var/cache/nginx

# make install Nginx

mkdir ~/works && cd ~/works/
wget https://nginx.org/download/nginx-1.18.0.tar.gz
tar zxvf nginx-1.18.0.tar.gz
cd nginx-1.18.0
git clone https://github.com/arut/nginx-rtmp-module.git
./configure --user=nginx --group=nginx --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=nginx --group=nginx --build=CentOS --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --add-module=nginx-rtmp-module/
make && make install


# add RTMP Setting to Nginx config
cat << EOF >>  /etc/nginx/nginx.conf
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            hls on;
            hls_path /etc/nginx/html;
            hls_fragment 5s;
            hls_type live;
        }
    }
}
EOF


# TEST Nginx Config
/usr/sbin/nginx -t

# add systemd Nginx Service conf
cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target
[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
[Install]
WantedBy=multi-user.target
EOF

# start Nginx,add systemd Nginx Service
service nginx start
systemctl enable nginx