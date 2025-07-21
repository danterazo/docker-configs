#!/bin/bash

# create app(s) config dir
mkdir -pv /apps/$(hostname)

# create handy symlinks in /root/
ln -sf /apps/$(hostname) /root/app
ln -sf /dockge-agent /root/dockge-agent
ln -sf /scripts /root/scripts

# create (if necessary) dante user and group
sudo groupadd -g 1000 dante
sudo useradd -u 1000 -g 1000 -M -s /bin/bash dante

# enable GPU access
groupadd -f video
groupadd -f render
usermod -aG video,render root
usermod -aG video,render dante

# reminders
echo -e "\nWhitelist MAC, set IP, and connect Dockge before proceeding!"

