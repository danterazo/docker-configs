# versioning
dpull() {
	cd "/docker/$(hostname)"
	git pull
    docker compose pull 2>/dev/null || docker compose build
	docker compose up -d --remove-orphans
}
