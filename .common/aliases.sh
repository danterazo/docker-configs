#!/bin/bash

# docker-compose-v2 syntax
alias dcp="docker compose pull"
alias dcd="docker compose down"
alias dcu="docker compose up -d"
alias dcr="docker compose restart"
alias dcl="docker compose logs -f"
alias logs="docker compose logs -f"

# list commands
alias dimg="docker image ls"
alias dnet="docker network ls"
alias dvol="docker volume ls"

# compose with project name inferred from folder
alias dcuu="docker compose up -d --remove-orphans"
alias dcpb="docker compose build --pull"

# functions
dpull() {
	cd "/docker/$(hostname)"
	git pull
    docker compose pull
	docker compose up -d --remove-orphans
}

# package management
alias upgrade='sudo apt update && sudo apt dist-upgrade -y && sudo apt clean && sudo apt autoremove -y --purge'
