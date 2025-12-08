#!/bin/bash

apt-get update -y
apt-get upgrade -y

apt-get install -y \
  haproxy \
  keepalived \
  systemd-timesyncd


# Enable services at boot time
systemctl enable systemd-timesyncd
systemctl enable haproxy
systemctl enable keepalived
