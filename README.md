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
```mermaid
flowchart TB
    rpool["rpool"] --> rpool_data["data vdev"]
    rpool_data --> rpool_mirror["mirror-0"]
    rpool_mirror --> rpool_ssd1["2TB T-FORCE TM8FP8002T"]
    rpool_mirror --> rpool_ssd2["2TB XPG GAMMIX S11 Pro"]

    classDef pool fill:#7c3aed,color:#fff
    classDef vdev fill:#2563eb,color:#fff
    classDef mirror fill:#059669,color:#fff
    classDef disk fill:#d97706,color:#fff

    class rpool pool
    class rpool_data vdev
    class rpool_mirror mirror
    class rpool_ssd1,rpool_ssd2 disk
```
```mermaid
flowchart TB
    tank["tank"]

    tank --> special["special vdev"]
    tank --> data["data vdev"]

    special --> special_mirror0["mirror-0"]
    special --> special_mirror1["mirror-1"]
    special_mirror0 --> special_ssd1["800GB SAS3 Toshiba SSD<br/>(PX02SMF080)"]
    special_mirror0 --> special_ssd2["800GB SAS3 Toshiba SSD<br/>(PX02SMF080)"]
    special_mirror1 --> special_ssd3["800GB SAS3 Toshiba SSD<br/>(PX02SMF080)"]
    special_mirror1 --> special_ssd4["800GB SAS3 Toshiba SSD<br/>(PX02SMF080)"]

    data --> data_mirror0["mirror-0"]
    data --> data_mirror1["mirror-1"]
    data_mirror0 --> data_hdd1["26TB SATA Seagate HDD<br/>7200rpm CMR<br/>(ST26000DM000-3Y8)"]
    data_mirror0 --> data_hdd2["26TB SATA Seagate HDD<br/>7200rpm CMR<br/>(ST26000DM000-3Y8)"]
    data_mirror1 --> data_hdd3["26TB SATA Seagate HDD<br/>7200rpm CMR<br/>(ST26000DM000-3Y8)"]
    data_mirror1 --> data_hdd4["26TB SATA Seagate HDD<br/>7200rpm CMR<br/>(ST26000DM000-3Y8)"]

    classDef pool fill:#7c3aed,color:#fff
    classDef vdev fill:#2563eb,color:#fff
    classDef mirror fill:#059669,color:#fff
    classDef disk fill:#d97706,color:#fff

    class tank pool
    class special,data vdev
    class special_mirror0,special_mirror1,data_mirror0,data_mirror1 mirror
    class special_ssd1,special_ssd2,special_ssd3,special_ssd4,data_hdd1,data_hdd2,data_hdd3,data_hdd4 disk
```

#### Hoppípolla
```mermaid
flowchart TB
    rpool["rpool"] --> rpool_data["data vdev"]
    rpool_data --> rpool_mirror["mirror-0"]
    rpool_mirror --> rpool_nvme1["2TB NVMe WD SSD (IX SN350<br/>SDBPNPZ-2T00-XI)"]
    rpool_mirror --> rpool_nvme2["2TB NVMe WD SSD (IX SN350<br/>SDBPNPZ-2T00-XI)"]

    classDef pool fill:#7c3aed,color:#fff
    classDef vdev fill:#2563eb,color:#fff
    classDef mirror fill:#059669,color:#fff
    classDef disk fill:#d97706,color:#fff

    class rpool pool
    class rpool_data vdev
    class rpool_mirror mirror
    class rpool_nvme1,rpool_nvme2 disk
```

#### Marigold
```mermaid
flowchart TB
    rpool["rpool"] --> rpool_data["data vdev"]
    rpool_data --> rpool_mirror["mirror-0"]
    rpool_mirror --> rpool_nvme1["2TB NVMe WD SSD (IX SN350<br/>SDBPNPZ-2T00-XI)"]
    rpool_mirror --> rpool_nvme2["2TB NVMe WD SSD (IX SN350<br/>SDBPNPZ-2T00-XI)"]

    classDef pool fill:#7c3aed,color:#fff
    classDef vdev fill:#2563eb,color:#fff
    classDef mirror fill:#059669,color:#fff
    classDef disk fill:#d97706,color:#fff

    class rpool pool
    class rpool_data vdev
    class rpool_mirror mirror
    class rpool_nvme1,rpool_nvme2 disk
```
