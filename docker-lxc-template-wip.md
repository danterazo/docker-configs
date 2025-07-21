# Docker LXC Template V2.0
## Changes
- bashrc common source?
- Install fastfetch + config
    - Use script you wrote to automate this in LXC template, but keep handy in case you need it in the future in .../docker/+scripts/
    - Script currently @ .../media/plex/

## Mount Points
```
mp0: /mnt/hdd-pool/apps/docker/+scripts,mp=/scripts,mountoptions=lazytime;noatime;nodev;nosuid,shared=1
mp1: /mnt/hdd-pool/apps/docker/dockge-agent,mp=/dockge-agent,mountoptions=lazytime;noatime;nodev;nosuid,shared=1
mp2: /mnt/hdd-pool/apps/docker/APPNAME,mp=/apps/APPNAME,mountoptions=lazytime;noatime;nodev;nosuid,shared=1
mp3: /mnt/hdd-pool/apps/docker/+volumes,mp=/transfer,mountoptions=lazytime;noatime;nodev;nosuid,shared=1,ro=1
```
