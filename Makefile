SHELL := /bin/bash
EXCLUDES := \( -path './.git' -o -path './.venv' -o -path './venv' -o -path './node_modules' -o -path './.vscode' -o -path './.wip' -o -path './tabby/source' \) -prune -o

.PHONY: fix format fix-text lint-compose-spacing lint-docker fix-caddy deps clean

# format everything
format: fix-python fix-caddy lint-compose-spacing lint-docker

# alias
fix: format

fix-text:
	prettier --write .

lint-compose-spacing:
	python scripts/lint-compose-spacing.py

lint-docker:
	find . \( -path './.git' -o -path './.venv' -o -path './venv' -o -path './node_modules' -o -path './.vscode' -o -path './tabby/source' -o -path './.wip/tabby/source' \) -prune -o -type f \( -name 'Dockerfile' -o -name 'Dockerfile.*' \) -print0 \
		| xargs -0 -I {} sh -c 'docker buildx build --check --file "$$1" "$$(dirname "$$1")"' _ {}

fix-caddy:
	find caddy/configs -type f \( -name 'Caddyfile*' -o -name '*.conf' \) -printf '%P\0' \
		| xargs -0 -r -I {} docker run --rm \
			--user "$$(id -u):$$(id -g)" \
			--mount "type=bind,source=$(CURDIR)/caddy/configs,target=/etc/caddy" \
			caddy:alpine caddy fmt --overwrite "/etc/caddy/{}"

fix-python:
	ruff check --fix .
	ruff format .

deps:
	poetry lock
	poetry update
	poetry install

clean:
	find . -type f \( -name 'Zone.Identifier' -o -name '*:Zone.Identifier' \) -print -delete
