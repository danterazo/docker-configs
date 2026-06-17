#!/bin/bash
## bootstrap PVE Docker LXCs

: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"
UBUNTU_CODENAME="resolute"

: 'INSTALL HELPFUL PACKAGES'
apt update
apt install -y tree ca-certificates curl git software-properties-common nfs-common iotop bash-completion

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
Suites: ${UBUNTU_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
apt install -y docker-ce docker-ce-cli containerd.io \
	docker-buildx-plugin docker-compose-plugin


: 'CONFIGURE DOCKER'
if [ ! -f /etc/docker/daemon.json ]; then
	install -m 0755 -d /etc/docker
	cat >/etc/docker/daemon.json <<'EOF'
{
	"log-driver": "json-file",
	"log-opts": {
		"max-size": "20m",
		"max-file": "5"
	}
}
EOF

	# reload if systemd is available
	if command -v systemctl >/dev/null 2>&1; then
		systemctl restart docker || true
	fi
fi

# TODO: set up SSH key sharing

: 'GIT CONFIG'
git config --global user.name "Dante Razo"
git config --global user.email "github.d2brf@simplelogin.fr"
git config --global pull.rebase false
git config --global --add safe.directory /docker


: 'INIT CONFIG REPOSITORY'
mkdir -p "${ROOT_DIR}"

if [ ! -d "${ROOT_DIR}/.git" ]; then
	# first-time setup; clone repository
	if ! git clone --filter=blob:none --sparse \
		git@github.com:danterazo/docker-configs.git \
		"${ROOT_DIR}"; then
		echo "ERROR: Failed to clone repository" >&2
		exit 1
	fi
else
	# repo already exists; just update
	cd "${ROOT_DIR}"
	git pull --ff-only 2>/dev/null || true
fi

cd "${ROOT_DIR}"

# configure sparse-checkout
git sparse-checkout init --cone 2>/dev/null || true
git sparse-checkout set .common "${APP_NAME}" 2>/dev/null || true

# remove community-scripts details loader
rm -f /etc/profile.d/00_lxc-details.sh || true


: 'INIT PERMISSIONS'
# create dante group if missing
if ! getent group dante >/dev/null; then
	groupadd -g 1000 dante
fi

# create dante user if missing
if ! id -u dante >/dev/null 2>&1; then
	useradd -u 1000 -g 1000 -m -d /home/dante -s /bin/bash dante
fi

# enable GPU access
groupadd -f video
groupadd -f render
usermod -aG video,render root || true
usermod -aG video,render dante || true

# fix bind permissions
chown -R dante:dante "${ROOT_DIR}"


: 'BASH CONFIG'
# share one bashrc entrypoint across accounts
if [ ! -f /docker/.common/bashrc.sh ]; then
	echo "ERROR: /docker/.common/bashrc.sh not found. Sparse-checkout may have failed." >&2
	exit 1
fi

# create symlinks
mkdir -p /home/dante
ln -sf /docker/.common/bashrc.sh /root/.bashrc
ln -sf /docker/.common/bashrc.sh /home/dante/.bashrc


: 'NOTICES TO USER'
echo -e "\nDouble-check IP in PVE UI before proceeding! \n\n"
