#!/bin/bash

: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"

: 'INSTALL HELPFUL PACKAGES'
apt update
apt install -y tree ca-certificates curl git

: 'INSTALL DOCKER'
# add docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	-o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# add the repository to apt sources
cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
apt install -y docker-ce docker-ce-cli containerd.io \
	docker-buildx-plugin docker-compose-plugin

: 'INIT CONFIG REPOSITORY'
git clone --filter=blob:none --sparse \
	git@github.com:danterazo/docker-configs.git \
	"${ROOT_DIR}"

cd "${ROOT_DIR}"

git sparse-checkout init --cone

# include .common-scripts and this app's dir
git sparse-checkout set \
	.common-scripts \
	"${APP_NAME}"

# enable automatic cd
ln -sf "${ROOT_DIR}/.common-scripts/auto-cd.sh" \
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
echo -e "\nDouble-check IP in PVE UI before proceeding!\n\n"
