#!/bin/bash

: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"

: 'INSTALL HELPFUL PACKAGES'
sudo apt install tree


: 'INSTALL DOCKER'
# add docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# add the repository to apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

# install docker packages
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


: 'INIT CONFIG REPOSITORY'
git clone --filter=blob:none --sparse \
  https://github.com/danterazo/docker-configs.git \
  ${ROOT_DIR}

# enter new directory
cd ${ROOT_DIR}

# enable sparse checkout
git sparse-checkout init --cone

# sparse checkout relevant directories
git sparse-checkout set .common-scripts \
  ${APP_NAME}

# enable automatic cd
ln -sf ${ROOT_DIR}/.common-scripts/auto-cd.sh \
	/etc/profile.d/00-auto-cd.sh


: 'INIT PERMISSIONS'
# create dante group if missing
if ! getent group dante >/dev/null; then
	groupadd -g 1000 dante
fi

# create dante user if missing
if ! id -u dante >/dev/null 2>&1; then
	useradd -u 1000 -g 1000 -M -s /bin/bash dante
fi

# enable GPU access
groupadd -f video
groupadd -f render
usermod -aG video,render root || true
usermod -aG video,render dante || true


: 'NOTICES TO USER'
# reminders
echo -e "\nDouble-check IP in PVE UI before proceeding!"
