#!/bin/bash
## update all LXCs
set -e

LXCS=(100 101)

for lxc in "${LXCS[@]}"; do
  ip="192.168.30.$lxc"
  echo "Updating LXC $lxc @ $ip..."

  ssh root@ip 'update'
done

echo -e "\nAll LXCs updated successfully!\n"
