# rtmp-streaming-server build script for AWS Amazon Linux2
A rtmp streaming server build script for nginx/tengine/openResty.

# System requirement:

Amazon Linux release 2 (Karoo)

# Usage:

```
sudo bash ./setup_nginx-rtmp-server.sh
sudo bash ./setup_nginx-rtmp-monitoring.sh
```

## RTMP distribution setting

#### Server
rtmp://{SERVER-NAME}/live/
#### StreamKey
UniqueName (non-overlapping)


## RTMP reception setting
rtmp://{SERVER-NAME}/live/{StreamKey}

# RTMP Monitoring
http://{SERVER-NAME}:9991

User / Password : Set "setup_nginx-rtmp-monitoring.sh"