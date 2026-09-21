#!/bin/bash
## bootstrap PVE Docker LXCs


: 'GLOBAL CONFIG'
APP_NAME="$(hostname)"
ROOT_DIR="/docker"
UBUNTU_CODENAME="resolute" # TODO: remove after Ubuntu 26.10 stable release
GIT_SPARSE=1

# pin Ubuntu release to stable / normal
sudo sed -i 's/^Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades


: 'INSTALL PACKAGES'
sudo apt-get update
sudo apt-get install -y tree ca-certificates curl git software-properties-common nfs-common iotop bash-completion lsb-release fastfetch

# remove the obsolete fastfetch PPA when it is configured
if grep -Rqs 'ppa:zhangsongcui3371/fastfetch' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
	sudo add-apt-repository --remove ppa:zhangsongcui3371/fastfetch -y || true
fi


: 'INSTALL DOCKER'
# add docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	sudo tee /etc/apt/keyrings/docker.asc >/dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# TODO: replace Suites definition after Ubuntu 26.10 stable release
# add the repository to apt sources
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME}
# Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
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

: 'INIT USER'
# create dante group if missing
if ! getent group dante >/dev/null; then
	sudo groupadd -g 1000 dante
fi

# create dante user if missing
if ! id -u dante >/dev/null 2>&1; then
	sudo useradd -u 1000 -g 1000 -m -d /home/dante -s /bin/bash dante
fi


: 'GIT CONFIG'
git config --global user.name "Dante Razo"
git config --global user.email "github.d2brf@simplelogin.fr"
git config --global pull.rebase false


: 'INIT CONFIG REPOSITORY'
sudo mkdir -p "${ROOT_DIR}"
sudo chown -R dante:dante "${ROOT_DIR}"

# TODO: set up SSH key sharing
# fix SSH permissions, preferring dante's key over root's
SSH_DIR=""
for path in /home/dante/.ssh /root/.ssh; do
	if [ -f "${path}/id_ed25519" ] && [ -f "${path}/id_ed25519.pub" ]; then
		SSH_DIR="${path}"
		break
	fi
done

if [ -n "${SSH_DIR}" ]; then
	sudo chmod 700 "${SSH_DIR}"
	sudo chmod 600 "${SSH_DIR}/id_ed25519"
	sudo chmod 644 "${SSH_DIR}/id_ed25519.pub"
	export GIT_SSH_COMMAND="ssh -i ${SSH_DIR}/id_ed25519 -o IdentitiesOnly=yes"
fi

REPO_CREATED=0
if [ ! -d "${ROOT_DIR}/.git" ]; then
	# first-time setup; clone repository
	clone_args=()
	if [ "${GIT_SPARSE}" = "1" ]; then
		clone_args+=(--filter=blob:none --sparse)
	fi

	if ! git clone "${clone_args[@]}" \
		git@github.com:danterazo/docker-configs.git \
		"${ROOT_DIR}"; then
		echo "ERROR: Failed to clone repository"
		exit 1
	fi
	REPO_CREATED=1
else
	# repo already exists; preserve its sparse-checkout configuration
	echo "WARNING: Repository already exists at ${ROOT_DIR}; preserving checkout settings..."
fi

# move to root-level repo directory
cd "${ROOT_DIR}"
if [ "${REPO_CREATED}" = "0" ]; then
	git pull
fi

# configure sparse-checkout for the host's layout
if [ "${GIT_SPARSE}" = "1" ]; then
	if [ -n "$(git ls-tree -d --name-only HEAD -- "${APP_NAME}")" ]; then
		git sparse-checkout set --cone .common "${APP_NAME}" 2>/dev/null || true
	else
		git sparse-checkout disable 2>/dev/null || true
	fi
else
	git sparse-checkout disable 2>/dev/null || true
fi

# move to app dir if the host contains only a single stack
if [ -d "${ROOT_DIR}/${APP_NAME}" ]; then
    # should exist in single-stack hosts
	cd "${ROOT_DIR}/${APP_NAME}"
else
    # should exist in both single-stack and multi-stack hosts
	cd "${ROOT_DIR}"
fi


: 'INIT PROFILE'
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

# link the shared fastfetch config to both root and dante users
FASTFETCH_CONFIG="${ROOT_DIR}/.common/configs/fastfetch/config.jsonc"
if [ -f "${FASTFETCH_CONFIG}" ]; then
	for user_home in /home/dante /root; do
		sudo install -d -o "$(basename "${user_home}")" -g "$(basename "${user_home}")" "${user_home}/.config/fastfetch"
		sudo ln -sf "${FASTFETCH_CONFIG}" "${user_home}/.config/fastfetch/config.jsonc"
	done
else
	echo "ERROR: ${FASTFETCH_CONFIG} not found. Sparse-checkout may have failed."
	exit 1
fi

# use canonical's suggested marker files
sudo touch /var/lib/update-notifier/hide-esm-in-motd
sudo touch /var/lib/ubuntu-advantage/hide-esm-in-motd
sudo pro config set apt_news=false

# delete every update-motd.d file, with some exceptions
shopt -s extglob
sudo rm -fv /etc/update-motd.d/!(85-fwupd.dpkg-dist|98-reboot-required)
shopt -u extglob

# disable SSH login message
sudo sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config


: 'INIT PERMISSIONS'
# enable GPU access
sudo groupadd -f video
sudo groupadd -f render
sudo usermod -aG video,render,docker root || true
sudo usermod -aG video,render,docker dante || true

# fix bind permissions
sudo chown -R dante:dante "${ROOT_DIR}"

# grant dante passwordless reboot/poweroff/shutdown/apt
sudo tee /etc/sudoers.d/dante > /dev/null <<'EOF'
dante ALL=(root) NOPASSWD: /usr/sbin/reboot, /usr/sbin/poweroff, /usr/sbin/shutdown, /usr/bin/apt-get update, /usr/bin/apt-get dist-upgrade, /usr/bin/apt-get clean, /usr/bin/apt-get autoremove
EOF
sudo chmod 0440 /etc/sudoers.d/dante
sudo visudo -c	# validate sudoer file syntax


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


: 'LOGS FOR USER'
echo -e "\nDouble-check IP in PVE UI before proceeding! \n\n"
