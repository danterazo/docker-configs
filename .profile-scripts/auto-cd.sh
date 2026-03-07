#!/bin/bash

ROOT_DIR="/docker"
APP_DIR="${ROOT_DIR}/$(hostname)"

if [ -d "$APP_DIR" ] && [ -z "$NO_AUTO_CD" ]; then
	cd "$APP_DIR"
fi
