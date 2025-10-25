FROM caddy:builder AS builder

# install plugins
RUN xcaddy build \
	--with github.com/caddy-dns/cloudflare \
	--with github.com/greenpau/caddy-security

# faster -> caddy:alpine
FROM caddy:alpine

# copy plugins
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
