#!/bin/bash

# Configuration
STACKS=("dawarich" "thunderbird" "immich")
COMPOSE_DIR="/self-hosted"
DATETIME=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)
BACKUP_DIR="/mnt/mega-pool/backups/containers/kex/${HOSTNAME}"
#LOG_FILE="/var/log/docker-volume-backup.log"
COMPRESSION_LEVEL=9

# Define volumes to back up
VOLUMES=(
"calibre_config"

"dawarich_photon"
"dawarich_postgres"
"dawarich_public"
"dawarich_redis"
"dawarich_shared-db"
"dawarich_storage"

"dockge_db"

"immich_db"

"planka_attachments"
"planka_avatars"
"planka_backgrounds"
"planka_db"

"pocket-id_db"

"qbittorrent_config"
"qbittorrent_ui"

"radicale_data"

"soulseek_db"

"speedtest-main_db"
"speedtest-vpn_db"

"strava-stats_build"
"strava-stats_db"
"strava-stats_logs"
"strava-stats_storage"

"syncthing_db"

"thunderbird_appdata"
"thunderbird_mail"
"proton-mail-bridge_data"

"traccar_db"
"traccar_logs"

"urbackup_appdata"
"urbackup_clients"
"urbackup_db"
"urbackup_www"
)

echo "Starting backup of Docker stacks at $(date)"

for STACK in "${STACKS[@]}"; do
    echo "Processing stack: $STACK"

    # Navigate to stack directory
    cd "$COMPOSE_DIR/$STACK" || {
        echo "ERROR: Could not find directory $COMPOSE_DIR/$STACK"
        continue
    }

    # Get volumes used by this stack before stopping
    #echo -e "Getting volumes for stack $STACK...\n"
    #VOLUMES=$(docker compose ps -q 2>/dev/null | xargs -r docker inspect --format '{{range .Mounts}}{{if .Name}}{{.Name}} {{end}}{{end}}' 2>/dev/null | tr ' ' '\n' | sort | uniq | grep -v '^$')

    # If no running containers, try to get volumes by stack name prefix
    #if [ -z "$VOLUMES" ]; then
    #    echo "No running containers found, trying to get volumes by prefix..."
    #    VOLUMES=$(docker volume ls -q | grep "^${STACK}_")
    #fi

    #if [ -z "$VOLUMES" ]; then
    #    echo "WARNING: No volumes found for stack $STACK"
    #    continue
    #fi

    #echo "Found volumes for $STACK: $VOLUMES"

    # Stop the stack
    echo "Stopping stack $STACK..."
    docker compose down

    # Get volume paths
    VOLUME_PATHS=()
    for VOLUME in $VOLUMES; do
        VOLUME_PATHS+=("/var/lib/docker/volumes/$VOLUME")
    done

    # Compress
    FILE_PATH="$BACKUP_DIR/${STACK}/${STACK}_${DATETIME}.7z"
    7z a -t7z -m0=lzma2 -mmt -ms=on -mx=$COMPRESSION_LEVEL "${FILE_PATH}" "${VOLUME_PATHS[@]}"

    # Verify archive integrity
    if [ -f "${FILE_PATH}" ]; then
        7z t "${FILE_PATH}" #>/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Success: $VOLUME backup verified"
        else
            echo "ERROR: Backup verification failed for $VOLUME"
            rm -f "${FILE_PATH}"
        fi
    else
        echo "ERROR: Backup file not created for $VOLUME"
    fi

    # Cleanup
    rm -rf "$STACK_TMP"

    # Restart the stack
    echo "Starting stack: $STACK..."
    docker compose up -d || true

    echo "Finished processing stack: $STACK"
done

echo "Backup of ${HOSTNAME} completed @ $(date)!"

# Prepare to cull backups
cd "${BACKUP_DIR}"

# Keep only the 7 latest backups for each stack
ls -1d */ | sort | head -n -7 | xargs -r rm -rf

# sync backups to B2 for safekeeping
rclone sync "${BACKUP_DIR}" \
	b2-docker-prod:ssk-docker-prod/ \
        --transfers=32 \
        --b2-chunk-size=900M \
        --fast-list \
        --progress \
        --size-only \
        --b2-hard-delete
#	-v
