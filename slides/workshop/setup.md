## Set up Our Lab

Running on k3d

- We're going to start out training with [k3d](https://k3d.io) 

- It spins up `k3s` inside containers. Each node in the cluster is actually a container.

- This doesn't provide resource isolation, but it's good enough for what we want to showcase.

---
## Create the Cluster

.lab[
```bash
    git clone https://github.com/otomato-gh/k8s-o10n-workshop.git
    cd k8s-o10n-workshop/scripts
    ./setup.sh
```
]

Verify the cluster was created:
.lab[
```bash
newgrp docker 
k3d kubeconfig get training > $HOME/.kube/config
kubectl get node
```
]