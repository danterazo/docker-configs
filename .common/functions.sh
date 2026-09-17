#!/bin/bash

# versioning
dpull() {
	cd "/docker/$(hostname)"
	git pull
	docker compose pull --ignore-buildable
	docker compose build --pull --no-cache
	docker compose up --build -d --remove-orphans
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
