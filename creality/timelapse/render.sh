#!/usr/bin/env bash
set -Eeuo pipefail

DATA="/tank/printing/timelapse"
FRAMES="${DATA}/frames"
RENDERED="${DATA}/rendered"
ARCHIVE="${DATA}/archive"
LOCK="/tmp/k1c-timelapse-render.lock"
PRINTER="vardeldur"

FPS="${FPS:-30}"
CRF="${CRF:-20}"
PRESET="${PRESET:-medium}"
MAX_WIDTH="${MAX_WIDTH:-1920}"
STABILITY_SECONDS="${STABILITY_SECONDS:-30}"

exec 9>"${LOCK}"

if ! flock -n 9; then
    echo "A timelapse render is already active or queued."
    exit 0
fi

mkdir -p "${FRAMES}" "${RENDERED}" "${ARCHIVE}"

shopt -s nullglob
before=( "${FRAMES}"/frame*.jpg )

if (( ${#before[@]} == 0 )); then
    echo "No timelapse frames found."
    exit 1
fi

before_state="$(
    for frame in "${before[@]}"; do
        stat -c '%n:%s:%Y' "${frame}"
    done | sort
)"

sleep "${STABILITY_SECONDS}"

after=( "${FRAMES}"/frame*.jpg )

if (( ${#after[@]} == 0 )); then
    echo "Frames disappeared while waiting."
    exit 1
fi

after_state="$(
    for frame in "${after[@]}"; do
        stat -c '%n:%s:%Y' "${frame}"
    done | sort
)"

if [[ "${before_state}" != "${after_state}" ]]; then
    echo "Frames are still changing; not rendering."
    exit 1
fi

job_id="${PRINTER}-$(date -u +%Y%m%dT%H%M%SZ)"
job_dir="${ARCHIVE}/${job_id}"
partial="${RENDERED}/.${job_id}.partial.mp4"
output="${RENDERED}/${job_id}.mp4"

mkdir -- "${job_dir}"

for frame in "${after[@]}"; do
    mv -- "${frame}" "${job_dir}/"
done

docker run --rm \
    --user 1000:1000 \
    -v "${DATA}:/data:rw" \
    jrottenberg/ffmpeg:7.1-alpine \
    -hide_banner \
    -nostdin \
    -y \
    -framerate "${FPS}" \
    -start_number 1 \
    -i "/data/archive/${job_id}/frame%06d.jpg" \
    -vf "scale='min(${MAX_WIDTH},iw)':-2:flags=lanczos,format=yuv420p" \
    -c:v libx264 \
    -preset "${PRESET}" \
    -crf "${CRF}" \
    -movflags +faststart \
    "/data/rendered/.${job_id}.partial.mp4"

mv -- "${partial}" "${output}"

echo "Rendered: ${output}"
