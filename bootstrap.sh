#!/bin/bash
## bootstrap PVE Docker LXCs

: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"

: 'INSTALL HELPFUL PACKAGES'
apt update
apt install -y tree ca-certificates curl git software-properties-common

# install fastfetch
add-apt-repository -y ppa:zhangsongcui3371/fastfetch
apt update
apt install -y fastfetch


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

# TODO: set up SSH key sharing

: 'INIT CONFIG REPOSITORY'
if [ ! -d "${ROOT_DIR}/.git" ]; then
	# first-time setup; clone and init sparse-checkout
	git clone --filter=blob:none --sparse \
		git@github.com:danterazo/docker-configs.git \
		"${ROOT_DIR}"

	cd "${ROOT_DIR}"

	git sparse-checkout init --cone
	git sparse-checkout set \
		.profile-scripts \
		"${APP_NAME}"
else
	# repo already exists; just update
	cd "${ROOT_DIR}"
	git pull --ff-only
fi

# include .profile-scripts and this app's dir
git sparse-checkout set \
	.profile-scripts \
	"${APP_NAME}"

# link all common profile scripts into /etc/profile.d
for script in "${ROOT_DIR}"/.profile-scripts/*.sh; do
	# skip if glob didn't match anything
	[ -e "$script" ] || continue

	base="$(basename "$script")"
	ln -sf "$script" "/etc/profile.d/00-${base}"
done

# remove community-scripts details loader
rm -f /etc/profile.d/00_lxc-details.sh || true


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

# fix bind permissions
chown -R dante:dante "${ROOT_DIR}"


: 'GIT CONFIG'
git config --global user.name "Dante Razo"
git config --global user.email "github.d2brf@simplelogin.fr"
git config pull.rebase false
git config --global --add safe.directory /docker


: 'NOTICES TO USER'
echo -e "\nDouble-check IP in PVE UI before proceeding! \n\n"
