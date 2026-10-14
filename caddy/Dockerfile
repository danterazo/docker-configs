FROM caddy:alpine

# full caddy URL, with desired plugins
ARG TARGETARCH=amd64
ARG CADDY_URL="https://caddyserver.com/api/download?os=linux&arch=${TARGETARCH}\
&p=github.com/caddy-dns/cloudflare\
&p=github.com/greenpau/caddy-security"

RUN wget -O /usr/bin/caddy "${CADDY_URL}" \
	&& chmod +x /usr/bin/caddy
