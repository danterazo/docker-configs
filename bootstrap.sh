#!/bin/bash
## bootstrap PVE Docker LXCs

: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"
UBUNTU_CODENAME="resolute"

: 'INSTALL HELPFUL PACKAGES'
sudo apt update
sudo apt install -y tree ca-certificates curl git software-properties-common nfs-common iotop bash-completion lsb-release

# install fastfetch & PPA
# sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y
sudo apt install -y fastfetch || true


: 'INSTALL DOCKER'
# add docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	sudo tee /etc/apt/keyrings/docker.asc >/dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# add the repository to apt sources
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
	docker-buildx-plugin docker-compose-plugin


: 'CONFIGURE DOCKER'
if [ ! -f /etc/docker/daemon.json ]; then
	sudo install -m 0755 -d /etc/docker
	sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
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
		sudo systemctl restart docker || true
	fi
fi

# TODO: set up SSH key sharing

: 'GIT CONFIG'
git config --global user.name "Dante Razo"
git config --global user.email "github.d2brf@simplelogin.fr"
git config --global pull.rebase false
sudo git config --global --add safe.directory /docker

# fix SSH permissions
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/id_ed25519
sudo chmod 644 /root/.ssh/id_ed25519.pub
sudo chown -R root:root /root/.ssh


: 'INIT CONFIG REPOSITORY'
sudo mkdir -p "${ROOT_DIR}"

if [ ! -d "${ROOT_DIR}/.git" ]; then
	# first-time setup; clone repository
	if ! sudo git clone --filter=blob:none --sparse \
		git@github.com:danterazo/docker-configs.git \
		"${ROOT_DIR}"; then
		echo "ERROR: Failed to clone repository"
		exit 1
	fi
else
	# repo already exists; just update
	cd "${ROOT_DIR}"
	if ! sudo git fetch --filter=blob:none --refetch --prune origin main; then
		echo "ERROR: Failed to fetch the latest repository state"
		exit 1
	fi
	sudo git reset --hard FETCH_HEAD
	sudo git clean -fd
fi

# move to root-level repo directory
cd "${ROOT_DIR}"

# configure sparse-checkout
sudo git sparse-checkout init --cone 2>/dev/null || true
sudo git sparse-checkout set .common "${APP_NAME}" 2>/dev/null || true
cd "${ROOT_DIR}/${APP_NAME}"

# clean up old profile.d symlinks
sudo find /etc/profile.d -maxdepth 1 -type l -name "00-*.sh" -delete 2>/dev/null || true

# remove community-scripts details loader
sudo rm -f /etc/profile.d/00_lxc-details.sh || true

# remove stale bash profile overrides
sudo rm -f /root/.bash_profile /home/dante/.bash_profile || true

# link common login-shell scripts into /etc/profile.d
for script in "${ROOT_DIR}"/.common/*.sh; do
	# skip if glob didn't match anything
	[ -e "$script" ] || continue

	base="$(basename "$script")"
	# don't link bashrc.sh (it's handled separately via .bashrc)
	[ "$base" = "bashrc.sh" ] && continue
	sudo ln -sf "$script" "/etc/profile.d/00-${base}"
done


: 'INIT PERMISSIONS'
# create dante group if missing
if ! getent group dante >/dev/null; then
	sudo groupadd -g 1000 dante
fi

# create dante user if missing
if ! id -u dante >/dev/null 2>&1; then
	sudo useradd -u 1000 -g 1000 -m -d /home/dante -s /bin/bash dante
fi

# enable GPU access
sudo groupadd -f video
sudo groupadd -f render
sudo usermod -aG video,render,docker root || true
sudo usermod -aG video,render,docker dante || true

# fix bind permissions
sudo chown -R dante:dante "${ROOT_DIR}"

: 'BASH CONFIG'
# share one bashrc entrypoint across accounts
if [ ! -f /docker/.common/bashrc.sh ]; then
	echo "ERROR: /docker/.common/bashrc.sh not found. Sparse-checkout may have failed."
	exit 1
fi

# create symlinks
sudo mkdir -p /home/dante
sudo ln -sf /docker/.common/bashrc.sh /root/.bashrc
sudo ln -sf /docker/.common/bashrc.sh /home/dante/.bashrc


: 'NOTICES TO USER'
echo -e "\nDouble-check IP in PVE UI before proceeding! \n\n"
