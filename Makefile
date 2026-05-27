EXCLUDES := \( -path './.git' -o -path './.venv' -o -path './venv' -o -path './node_modules' -o -path './.vscode' -o -path './.wip' -o -path './tabby/source' \) -prune -o

.PHONY: fix format fix-text fix-docker fix-caddy

# format everything
format: fix-text fix-docker fix-caddy

# alias
fix: format

fix-text:
	prettier --write .prettierrc.yaml
	prettier --write .

fix-docker:
	find . $(EXCLUDES) -type f \( -name 'Dockerfile' -o -name 'Dockerfile.*' \) -print0 \
		| xargs -0 -I {} sh -c 'dockfmt fmt "{}" | sponge "{}"'

fix-caddy:
	find caddy/configs -type f \( -name 'Caddyfile*' -o -name '*.conf' \) -print0 \
		| xargs -0 -I {} docker exec caddy caddy fmt --overwrite {}
