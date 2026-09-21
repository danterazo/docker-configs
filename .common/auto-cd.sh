#!/bin/bash

# global config
ROOT_DIR="/docker"
APP_DIR="${ROOT_DIR}/$(hostname)"

# move to app dir, if it exists
if [ -d "$APP_DIR" ]; then
	cd "$APP_DIR"
else
	cd "$ROOT_DIR"
fi
