# Dante's Docker Stacks
## Machines

|                          Machine                          |            Model             | CPU                   | RAM            | OS      | Filesystem | Nomenclature                                                                    |
| :-------------------------------------------------------: | :--------------------------: | :-------------------- | :------------- | :------ | :--------- | :------------------------------------------------------------------------------ |
|                            Kex                            |   Lenovo ThinkStation P510   | Intel Xeon E5-1650 v4 | 256GB DDR4 ECC | Proxmox | ZFS        | "Biscuit" in Icelandic, since it has many pieces (containers)                   |
| [Hoppípolla](https://www.youtube.com/watch?v=JAYb8ZyjzD0) | Lenovo ThinkStation P340 SFF | Intel Xeon W-1250     | 64GB DDR4 ECC  | Proxmox | ZFS        | Named after the [Sigur Rós](https://en.wikipedia.org/wiki/Sigur_R%C3%B3s) song  |
|  [Marigold](https://www.youtube.com/watch?v=CdqQzIDBd_Y)  |         Beelink EQ14         | Intel N150            | 32GB DDR4      | Proxmox | ZFS        | Named after the [Ocean Blue](https://en.wikipedia.org/wiki/The_Ocean_Blue) song |

## Storage
### ZFS Pools
#### Kex
```mermaid
flowchart LR
    rpool --> rpool_data["data vdev"]
    rpool_data --> rpool_mirror["mirror-0"]
    rpool_mirror --> rpool_ssd1["2TB NVMe 3.0 x4 T-FORCE TM8FP8002T"]
    rpool_mirror --> rpool_ssd2["2TB NVMe 3.0 x4 XPG GAMMIX S11 Pro"]

    tank --> special["special vdev"]
    tank --> data["data vdev"]

    special --> special_mirror0["mirror-2"]
    special --> special_mirror1["mirror-10"]
    special_mirror0 --> special_ssd1["800GB SAS3 Toshiba SSD<br>(PX02SMF080)"]
    special_mirror0 --> special_ssd2["800GB SAS3 Toshiba SSD<br>(PX02SMF080)"]
    special_mirror1 --> special_ssd3["800GB SAS3 Toshiba SSD<br>(PX02SMF080)"]
    special_mirror1 --> special_ssd4["800GB SAS3 Toshiba SSD<br>(PX02SMF080)"]

    data --> data_mirror0["mirror-6"]
    data --> data_mirror1["mirror-7"]
    data_mirror0 --> data_hdd1["26TB SATA Seagate HDD<br>CMR @ 7200RPM<br>(ST26000DM000-3Y8)"]
    data_mirror0 --> data_hdd2["26TB SATA Seagate HDD<br>CMR @ 7200RPM<br>(ST26000DM000-3Y8)"]
    data_mirror1 --> data_hdd3["26TB SATA Seagate HDD<br>CMR @ 7200RPM<br>(ST26000DM000-3Y8)"]
    data_mirror1 --> data_hdd4["26TB SATA Seagate HDD<br>CMR @ 7200RPM<br>(ST26000DM000-3Y8)"]

    classDef pool fill:#f5d0fe,color:#a21caf,stroke:#e879f9
    classDef vdev fill:#bae6fd,color:#075985,stroke:#38bdf8
    classDef mirror fill:#bbf7d0,color:#166534,stroke:#4ade80
    classDef disk fill:#fed7aa,color:#9a3412,stroke:#fb923c

    class rpool,tank pool
    class rpool_data,special,data vdev
    class rpool_mirror,special_mirror0,special_mirror1,data_mirror0,data_mirror1 mirror
    class rpool_ssd1,rpool_ssd2,special_ssd1,special_ssd2,special_ssd3,special_ssd4,data_hdd1,data_hdd2,data_hdd3,data_hdd4 disk
```

#### Hoppípolla
```mermaid
flowchart LR
    rpool --> rpool_data["data vdev"]
    rpool_data --> rpool_mirror["mirror-0"]
    rpool_mirror --> rpool_nvme1["2TB NVMe 3.0 x4<br>WD IX SN350<br>(SDBPNPZ-2T00-XI)"]
    rpool_mirror --> rpool_nvme2["2TB NVMe 3.0 x4<br>WD IX SN350<br>(SDBPNPZ-2T00-XI)"]

    classDef pool fill:#f5d0fe,color:#a21caf,stroke:#e879f9
    classDef vdev fill:#bae6fd,color:#075985,stroke:#38bdf8
    classDef mirror fill:#bbf7d0,color:#166534,stroke:#4ade80
    classDef disk fill:#fed7aa,color:#9a3412,stroke:#fb923c

    class rpool pool
    class rpool_data vdev
    class rpool_mirror mirror
    class rpool_nvme1,rpool_nvme2 disk
```

#### Marigold
```mermaid
flowchart LR
    rpool --> rpool_data["data vdev"]
    rpool_data --> rpool_mirror["mirror-0"]
    rpool_mirror --> rpool_nvme1["2TB NVMe 3.0 x4<br>WD IX SN350<br>(SDBPNPZ-2T00-XI)"]
    rpool_mirror --> rpool_nvme2["2TB NVMe 3.0 x1<br>WD IX SN350<br>(SDBPNPZ-2T00-XI)"]

    classDef pool fill:#f5d0fe,color:#a21caf,stroke:#e879f9
    classDef vdev fill:#bae6fd,color:#075985,stroke:#38bdf8
    classDef mirror fill:#bbf7d0,color:#166534,stroke:#4ade80
    classDef disk fill:#fed7aa,color:#9a3412,stroke:#fb923c

    class rpool pool
    class rpool_data vdev
    class rpool_mirror mirror
    class rpool_nvme1,rpool_nvme2 disk
```
