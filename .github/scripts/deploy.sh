#!/bin/bash
set -e

LXCS=(100 101)

for lxc in "${LXCS[@]}"; do
  ip="192.168.30.$lxc"
  echo "Updating LXC $lxc at $ip..."
  ssh root@$ip 'cd /apps && git pull && docker compose -f apps/$(hostname)/compose.yml up -d --build'
done

echo -e "\nAll LXCs updated successfully.\n"
