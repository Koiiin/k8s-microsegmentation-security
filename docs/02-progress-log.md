\# Progress Log



\## Milestone 1: VM and Network Preparation



\- Created 4 lightweight Ubuntu Server VMs.

\- Configured static IP for each VM.

\- Disabled cloud-init network override.

\- Disabled firewall for lab environment.

\- Disabled swap on Kubernetes nodes.

\- Enabled kernel modules: `overlay`, `br\_netfilter`.

\- Enabled `net.ipv4.ip\_forward`.



\## Milestone 2: Rancher Server



\- Installed Docker on `rancher-server`.

\- Deployed Rancher using `rancher/rancher:stable`.

\- Accessed Rancher UI at `https://192.168.113.10`.

\- Created admin account.



\## Milestone 3: RKE2 Cluster



\- Created custom RKE2 cluster named `k8s-security-cluster`.

\- Added `k8s-master-1` as Control Plane and etcd node.

\- Added `k8s-worker-1` and `k8s-worker-2` as worker nodes.

\- Cluster status: Active.



\## Milestone 4: Cilium and Hubble



\- Selected Cilium as container network during cluster creation.

\- Verified Cilium DaemonSet running on 3/3 nodes.

\- Enabled Hubble Relay and Hubble UI.

\- Opened Hubble UI using port-forward.



\## Milestone 5: Cross-node Traffic Demo



\- Deployed `client-netshoot` on `k8s-worker-1`.

\- Deployed `backend-nginx` on `k8s-worker-2`.

\- Verified HTTP traffic from client to backend.

\- Observed forwarded traffic in Hubble UI.

