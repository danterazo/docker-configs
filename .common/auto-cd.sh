#!/bin/bash

# global config
ROOT_DIR="/docker"
APP_DIR="${ROOT_DIR}/$(hostname)"

# move to app dir, if it exists
if [ -d "$APP_DIR" ]; then
    # should exist in LXCs
	cd "$APP_DIR"
else
    # should exist in both LXCs and VMs
	cd "$ROOT_DIR"
fi
