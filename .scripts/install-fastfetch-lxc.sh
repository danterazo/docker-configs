#!/bin/bash
## Install FastFetch within LXC

# enable add-apt-repository
sudo apt update
sudo apt install software-properties-common -y

# install script dependencies
sudo apt install jq -y

# upgrade other packages while you're at it
sudo apt upgrade -y

# clean up
sudo apt autoremove
sudo apt clean

# run fastfetch installer script
curl -sSL https://alessandromrc.github.io/fastfetch-installer/installer.sh | sudo bash

# create config file
sudo mkdir -p /root/.config/fastfetch

jq -n \
  --arg schema "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json" \
  --argjson logo '{"printRemaining":true}' \
  --argjson modules '["title","separator","kernel","os","cpu","gpu","separator","memory","uptime","cpuusage","separator","disk","separator","localip","separator","break"]' \
  '{
    "$schema": $schema,
    "logo": $logo,
    "modules": $modules
  }' | sudo tee /root/.config/fastfetch/config.jsonc

# check installation
fastfetch

# archive old motd scripts
MOTD_DIR="/etc/update-motd.d"
mkdir -v -p $MOTD_DIR/old
mv -v $MOTD_DIR/* $MOTD_DIR/old
chmod -v -x $MOTD_DIR/old/*

# move community motd
CS_MOTD_DIR="/etc/profile.d"
mkdir -v -p $CS_MOTD_DIR/old
mv -v $CS_MOTD_DIR/00_lxc-details.sh $CS_MOTD_DIR/old
chmod -v -x $CS_MOTD_DIR/old/*

# suppress mail alert system-wide
if ! grep -q '^unset MAILCHECK$' /etc/profile; then
  echo "\n#disable mail\nunset MAILCHECK\nMAILCHECK=-1\nbiff n\n" >>/etc/profile
fi

# suppress mail in crontab
if ! crontab -l 2>/dev/null | grep -q '^MAILTO=""$'; then
  (
    echo 'MAILTO=""\n'
    crontab -l 2>/dev/null
  ) | crontab -
fi

# create new motd w/ fastfetch
printf "#!/bin/sh\nfastfetch --pipe false\necho\n" >$MOTD_DIR/00-fastfetch
chmod -v +x $MOTD_DIR/00-fastfetch

# status report
echo -e "\nSuccessfully installed fastfetch and set MOTD!\n"
echo "Remember to add the following cronjob:\n@daily find /var/mail /var/spool/mail -type f -exec truncate -s 0 {} \;"
