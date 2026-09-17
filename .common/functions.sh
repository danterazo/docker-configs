#!/bin/bash

# versioning
dpull() {
	cd "/docker/$(hostname)"
	git pull
	docker compose pull --ignore-buildable
	docker compose build --pull --no-cache
	if docker compose up --build -d --remove-orphans; then
		return 0
	fi

	if [[ "$(basename "$PWD")" == gluetun ]]; then
		docker compose up --build -d --force-recreate --remove-orphans
		return $?
	fi

	return 1
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
