FROM caddy:alpine

# full caddy URL, with desired plugins
ARG TARGETARCH
ARG CADDY_URL="https://caddyserver.com/api/download?os=linux&arch=${TARGETARCH}\
&p=github.com/caddy-dns/cloudflare\
&p=github.com/greenpau/caddy-security"

# download and install caddy with the specified plugins
RUN wget --user-agent="curl/8.0" -O /usr/bin/caddy "${CADDY_URL}" \
    && chmod +x /usr/bin/caddy

# validate install
RUN	/usr/bin/caddy version \
    && /usr/bin/caddy list-modules | grep -qx 'dns.providers.cloudflare' \
    && /usr/bin/caddy list-modules | grep -qx 'security'
