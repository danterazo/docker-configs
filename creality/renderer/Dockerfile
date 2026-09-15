FROM alpine:3.21

RUN apk add --no-cache \
    bash \
    coreutils \
    ffmpeg \
    findutils \
    python3 \
    tzdata

WORKDIR /app

COPY renderer.py /app/renderer.py

RUN chmod 0755 /app/renderer.py && \
    addgroup -g 1000 renderer && \
    adduser -D -u 1000 -G renderer renderer

USER 1000:1000

EXPOSE 8095

ENTRYPOINT ["python3", "/app/renderer.py"]
