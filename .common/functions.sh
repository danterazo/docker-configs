# versioning
dpull() {
	cd "/docker/$(hostname)"
	git pull
	docker compose up --build -d --remove-orphans
}
