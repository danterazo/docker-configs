#!/bin/bash
## Deploy all Docker apps
set -e

LXCS=(100 101)

for lxc in "${LXCS[@]}"; do
  ip="192.168.30.$lxc"
  echo "Deploying apps on LXC $lxc @ $ip..."

  ssh root@"$ip" "docker compose -f /apps/apps/\$(hostname)/compose.yml up -d --build"
done

echo -e "\nAll LXC containers deployed successfully!\n"
