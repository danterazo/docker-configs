#!/bin/bash

# script config
BACKUP_DIR="/self-hosted/"

# sync backups to B2 for safekeeping
rclone sync "${BACKUP_DIR}" \
        b2-docker-prod:ssk-docker-prod/volume-backups \
        --transfers=32 \
        --b2-chunk-size=900M \
        --fast-list \
        --progress \
        --size-only \
        --b2-hard-delete \
	--exclude=".git/" \
	--exclude="dawarich/photon-db/"
