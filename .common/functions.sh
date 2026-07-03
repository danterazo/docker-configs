#!/bin/bash

# versioning
dpull() {
	cd "/docker/$(hostname)"
	git pull
	docker compose pull
	docker compose up --build -d --remove-orphans
}

# pull, then restart
drpull() {
	dpull
	reboot
}
