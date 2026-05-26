\# Environment Inventory



\## Host Machine



| Item | Value |

|---|---|

| OS | Windows |

| RAM | 16GB |

| Virtualization | VMware Workstation |

| Network Mode | NAT |

| VMnet | VMnet8 |

| Lab Subnet | 192.168.113.0/24 |

| Gateway | 192.168.113.2 |



\## Virtual Machines



| VM | Hostname | IP | CPU | RAM | Disk | Role |

|---|---|---|---:|---:|---:|---|

| VM1 | rancher-server | 192.168.113.10 | 2 | 3GB | 40GB | Rancher Server |

| VM2 | k8s-master-1 | 192.168.113.11 | 2 | 3GB | 40GB | RKE2 Control Plane + etcd |

| VM3 | k8s-worker-1 | 192.168.113.12 | 2 | 3GB | 40GB | Worker Node |

| VM4 | k8s-worker-2 | 192.168.113.13 | 2 | 3GB | 40GB | Worker Node |



\## Network Configuration



Static IP is configured using Netplan with cloud-init network configuration disabled.



Important files:



```text

/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

/etc/netplan/01-static.yaml

