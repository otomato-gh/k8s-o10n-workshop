## Kubernetes Performance Foundations

In this workshop we will be looking at optimizing the performance of applications running in a Kubernetes cluster.

Kubernetes or not - application performance is impacted by the following:
- Code efficiency
    -   Memory usage
    -   Stack depth
    -   Data structures
- Infrastructure Resource Availability:
    -   Storage
    -   Network
    -   Compute (cpu time)
    -   Memory
---
## Optimizing Kubernetes Storage

The following areas relate to storage:
- Container image storage
    -   Optimize container images
    -   Pre-Pull container images
- Ephemeral volumes
    - Local volumes
    - Remote volumes
- Persistent volume management

---
## Optimizing Kubernetes Networking

- The default `kube-proxy` relies on iptables and isn't particularly fast
- `kube-proxy` is probably good enough for you

- Unless you:
    - routinely saturate 10G network interfaces
    - count packet rates in millions per second
    - run high-traffic VOIP or gaming platforms
    - do weird things that involve millions of simultaneous connections
        (in which case you're already familiar with kernel tuning)

- If necessary, there are alternatives to kube-proxy; e.g. [kube-router](https://www.kube-router.io/)
---
## kube-router, IPVS

- It is possible to tell kube-proxy to use IPVS

- IPVS is a more powerful load balancing framework

(remember: iptables was primarily designed for firewalling, not load balancing!)

- It is also possible to replace kube-proxy with kube-router

    - kube-router uses IPVS by default

    - kube-router can also perform other functions

(e.g., we can use it as a CNI plugin to provide pod connectivity)

---

The following areas relate to storage:
- Container image storage
    -   Optimize container images
    -   Pre-Pull container images
- Pod volume mounts
    - Local volumes
    - Remote volumes
- Persistent volume management

---
## Measuring Resources on Kubernetes

Container resource allocation and consumption on Kubernetes is collected and exposed via the Metrics Pipeline:

<img align="right" src="images/metrics-pipeline.png">

- cAdvisor: Daemon for collecting, aggregating and exposing container metrics included in Kubelet.

- kubelet: The Node agent. Resource metrics are accessible using the /metrics/resource and /stats kubelet API endpoints.

- metrics-server: Cluster addon component that collects and aggregates resource metrics pulled from each kubelet. The API server serves Metrics API for use by HPA, VPA, and by the kubectl top command. Metrics Server is a reference implementation of the Metrics API.

<br clear="right"/>