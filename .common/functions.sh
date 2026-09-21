#!/bin/bash

# upgrade git and docker stacks
dpull() {
	# local variables
	local root_dir="/docker"
	local app_dir
	local compose_file

	# check git init status
	if [ ! -d "$root_dir/.git" ]; then
		echo "ERROR: .git directory missing from Docker configuration repository!"
		return 1
	fi

	# pull latest changes from git
	cd "$root_dir" || return 1
	git pull || return 1

	# iterate over each app directory and run docker compose commands
	for app_dir in "$root_dir"/*/; do
		[ -d "$app_dir" ] || continue

		while IFS= read -r compose_file; do
			cd "$(dirname "$compose_file")" || return 1
			docker compose pull --ignore-buildable || return 1
			docker compose build --pull --no-cache || return 1
			docker compose up --build -d --remove-orphans || return 1
		done < <(find "$app_dir" -type d -name '.*' -prune -o -type f \( -name compose.yaml -o -name compose.yml \) -print | sort)
	done
}

# upgrade packages, then pull
dupull() {
	upgrade
	dpull
}

# pull, upgrade packages, then restart
durpull() {
	upgrade
	dpull
	reboot
}
