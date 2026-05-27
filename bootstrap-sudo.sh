#!/bin/bash
## bootstrap (superuser) PVE Docker LXCs

: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"

: 'INSTALL HELPFUL PACKAGES'
sudo apt update
sudo apt install -y tree ca-certificates curl git software-properties-common

# install fastfetch
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install -y fastfetch


: 'INSTALL DOCKER'
# add docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# add the repository to apt sources
cat <<EOF | sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
	docker-buildx-plugin docker-compose-plugin

# TODO: set up SSH key sharing

: 'INIT CONFIG REPOSITORY'
if [ ! -d "${ROOT_DIR}/.git" ]; then
    # first-time setup; clone and init sparse-checkout
    sudo git clone --filter=blob:none --sparse \
        git@github.com:danterazo/docker-configs.git \
        "${ROOT_DIR}"

    cd "${ROOT_DIR}"

    sudo git sparse-checkout init --cone
    sudo git sparse-checkout set \
        .profile-scripts \
        "${APP_NAME}"
else
    # repo already exists; just update
    cd "${ROOT_DIR}"
    sudo git pull --ff-only
fi

# include .profile-scripts and this app's dir
sudo git sparse-checkout set \
    .profile-scripts \
    "${APP_NAME}"

# link all common profile scripts into /etc/profile.d
for script in "${ROOT_DIR}"/.profile-scripts/*.sh; do
    # skip if glob didn't match anything
    [ -e "$script" ] || continue

    base="$(basename "$script")"
    sudo ln -sf "$script" "/etc/profile.d/00-${base}"
done

# remove community-scripts details loader
sudo rm -f /etc/profile.d/00_lxc-details.sh || true


: 'INIT PERMISSIONS'
# create dante group if missing
if ! getent group dante >/dev/null; then
    sudo groupadd -g 1000 dante
fi

# create dante user if missing
if ! id -u dante >/dev/null 2>&1; then
    sudo useradd -u 1000 -g 1000 -M -s /bin/bash dante
fi

# enable GPU access
sudo groupadd -f video
sudo groupadd -f render
sudo usermod -aG video,render root || true
sudo usermod -aG video,render dante || true

# fix bind permissions
sudo chown -R dante:dante "${ROOT_DIR}"


: 'GIT CONFIG'
git config --global user.name "Dante Razo"
git config --global user.email "github.d2brf@simplelogin.fr"
git config pull.rebase false
sudo git config --global --add safe.directory /docker


: 'NOTICES TO USER'
echo -e "\nDouble-check IP in PVE UI before proceeding! \n\n"
