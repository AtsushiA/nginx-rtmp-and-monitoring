#!/usr/bin/env bash

# install real-time monitoring dashboard for nginx rtmp module for AWS Amazon Linux2
# Copyright : ando@next-season.net
# Version: 0.1
# Support: Amazon Linux 2
# Original: https://github.com/3m1o/nginx-rtmp-monitoring

# usage install : sudo bash ./setup_nginx-rtmp-monitoring.sh
# after install : open http://{id-address}:9991/

USERNAME=admin
PASSWORD=passw0rd
SESSION_SECRET_KEY=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1`
#https://gist.github.com/earthgecko/3089509


curl -sL https://rpm.nodesource.com/setup_8.x | sudo bash -
yum install -y nodejs

cd /etc/nginx/html/
git clone https://github.com/fiftysoft/nginx-rtmp-monitoring.git
mv /etc/nginx/html/nginx-rtmp-monitoring/stat.xsl /etc/nginx/html/
cd /etc/nginx/html/nginx-rtmp-monitoring/
npm install

npm install -g forever

# Make app config template
mkdir -p /opt/nginx-rtmp-monitoring/
cat << EOF > /opt/nginx-rtmp-monitoring/config.json
{
  "site_title":"RTMP Monitoring",
  "http_server_port":9991,
  "rtmp_server_refresh":3000,
  "rtmp_server_timeout":15000,
  "rtmp_server_url":"http://{SERVER_IP}/stat.xml",
  "rtmp_server_stream_url":"rtmp://{SERVER_IP}/live/",
  "rtmp_server_control_url":"http://{SERVER_IP}/control",
  "session_secret_key":"${SESSION_SECRET_KEY}",
  "username":"${USERNAME}",
  "password":"${PASSWORD}",
  "language":"en",
  "template":"default",
  "login_template":"login",
  "version":"1.0.2"
}
EOF

# Add node RTMP Monitoring Setting to nginx.conf
cat << EOF > /etc/nginx/conf.d/node.conf
            location /stat {
                rtmp_stat all;
                rtmp_stat_stylesheet stat.xsl;
            }

            location /stat.xsl {
            root html;
            }

            location /control {
                rtmp_control all;

                # Enable CORS
                add_header Access-Control-Allow-Origin * always;
            }
EOF

## Mod nginx.conf
sed -i -e 's/#include \/etc\/nginx\/conf.d\/node.conf;/include \/etc\/nginx\/conf.d\/node.conf;/g' /etc/nginx/nginx.conf


# setup crond nginx-rtmp-monitoring config update script
mkdir -p /opt/nginx-rtmp-monitoring/
cat << 'EOF' > /opt/nginx-rtmp-monitoring/update-nginx-rtmp-monitoring-settings.sh
#!/usr/bin/env bash

if [ `curl -m 5 -qf http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null | grep "i-" | wc -l` -gt 0 ]; then
  instance_ip=`curl -L http://169.254.169.254/latest/meta-data/public-ipv4`
else
  instance_ip=`curl -L https://ip.next-season.net`
fi

sed -e "s/{SERVER_IP}/${instance_ip}/g" /opt/nginx-rtmp-monitoring/config.json > /etc/nginx/html/nginx-rtmp-monitoring/config.json
cd /etc/nginx/html/nginx-rtmp-monitoring/ && forever start server.js
service nginx restart
echo "${instance_ip}" > /home/ec2-user/ip.txt
EOF

chmod +x /opt/nginx-rtmp-monitoring/update-nginx-rtmp-monitoring-settings.sh
bash /opt/nginx-rtmp-monitoring/update-nginx-rtmp-monitoring-settings.sh

cat << EOF > /opt/nginx-rtmp-monitoring/crontab
@reboot /opt/nginx-rtmp-monitoring/update-nginx-rtmp-monitoring-settings.sh
EOF

crontab /opt/nginx-rtmp-monitoring/crontab

# restart crond
service crond restart