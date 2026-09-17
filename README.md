# Dante's Docker Stacks
## Machines

|                          Machine                          |            Model             |                  Specs                  |     OS     | Notes                                                                           |
| :-------------------------------------------------------: | :--------------------------: | :-------------------------------------: | :--------: | :------------------------------------------------------------------------------ |
|                            Kex                            |   Lenovo ThinkStation P510   | Xeon E5-1650 v4, 256GB DDR4 RDIMM (ECC) | Proxmox VE | "Biscuit" in Icelandic, since it has many pieces (containers)                   |
| [Hoppípolla](https://www.youtube.com/watch?v=JAYb8ZyjzD0) | Lenovo ThinkStation P340 SFF |   Xeon W-1250, 64GB DDR4 UDIMM (ECC)    | Proxmox VE | Named after the [Sigur Rós](https://en.wikipedia.org/wiki/Sigur_R%C3%B3s) song  |
|  [Marigold](https://www.youtube.com/watch?v=CdqQzIDBd_Y)  |         Beelink EQ14         |   Intel N150, 32GB DDR4 SODIMM (ECC)    | Proxmox VE | Named after the [Ocean Blue](https://en.wikipedia.org/wiki/The_Ocean_Blue) song |

## Storage
### ZFS Pools
#### Kex
```text
rpool
└── data vdev
    └── mirror-0
        ├── 2TB T-FORCE TM8FP8002T
        └── 2TB XPG GAMMIX S11 Pro
```
```text
tank
├── special vdev
│   ├── mirror-0
│   │   ├── 800GB SAS3 Toshiba SSD (PX02SMF080)
│   │   └── 800GB SAS3 Toshiba SSD (PX02SMF080)
│   └── mirror-1
│       ├── 800GB SAS3 Toshiba SSD (PX02SMF080)
│       └── 800GB SAS3 Toshiba SSD (PX02SMF080)
└── data vdev
    ├── mirror-0
    │   ├── 26TB SATA Seagate HDD, 7200rpm CMR (ST26000DM000-3Y8)
    │   └── 26TB SATA Seagate HDD, 7200rpm CMR (ST26000DM000-3Y8)
    └── mirror-1
        ├── 26TB SATA Seagate HDD, 7200rpm CMR (ST26000DM000-3Y8)
        └── 26TB SATA Seagate HDD, 7200rpm CMR (ST26000DM000-3Y8)
```

#### Hoppípolla
```text
rpool
└── data vdev
    └── mirror-0
        ├── 2TB WD IX SN350 SDBPNPZ-2T00-XI
        └── 2TB WD IX SN350 SDBPNPZ-2T00-XI
```

#### Marigold
```text
rpool
└── data vdev
    └── mirror-0
        ├── 2TB WD IX SN350 SDBPNPZ-2T00-XI
        └── 2TB WD IX SN350 SDBPNPZ-2T00-XI
```
