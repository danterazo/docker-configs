FROM alpine:latest

RUN apk add --no-cache \
    bash \
    coreutils \
    ffmpeg \
    findutils \
    python3 \
    tzdata

WORKDIR /app

COPY render.py /app/render.py

RUN chmod 0755 /app/render.py && \
    addgroup -g 1000 render && \
    adduser -D -u 1000 -G render render

USER 1000:1000

EXPOSE 8095

ENTRYPOINT ["python3", "/app/render.py"]
