SHELL := /bin/bash
EXCLUDES := \( -path './.git' -o -path './.venv' -o -path './venv' -o -path './node_modules' -o -path './.vscode' -o -path './.wip' -o -path './tabby/source' \) -prune -o

.PHONY: fix format fix-text lint-compose-spacing lint-docker fix-caddy deps

# format everything
format: fix-text fix-python

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
	find caddy/configs -type f \( -name 'Caddyfile*' -o -name '*.conf' \) -print0 \
		| xargs -0 -I {} docker exec caddy caddy fmt --overwrite {}

fix-python:
	ruff check --fix .
	ruff format .

deps:
	poetry lock
	poetry update
	poetry install
