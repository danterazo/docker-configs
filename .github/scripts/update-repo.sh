#!/bin/bash
## Pull changes in all Git repos
set -e

LXCS=(100 101)

for lxc in "${LXCS[@]}"; do
  ip="192.168.30.$lxc"
  echo "Pulling on LXC $lxc @ $ip..."

  ssh root@$ip 'git pull'
done

echo -e "\nAll repositories pulled successfully!\n"
