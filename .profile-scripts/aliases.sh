#!/bin/bash

# only define aliases for interactive shells
case $- in
	*i*) ;;
	*) return ;;
esac

# prefer docker compose v2 syntax
alias dcp="docker compose pull"
alias dcd="docker compose down -v"
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
