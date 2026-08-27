#!/bin/bash

# versioning
dpull() {
	cd "/docker/$(hostname)"
	git pull
	docker compose pull
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
