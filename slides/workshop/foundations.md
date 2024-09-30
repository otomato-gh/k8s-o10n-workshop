# Kubernetes Performance Foundations

In this workshop we will be looking at optimizing the performance of applications running in a Kubernetes cluster.

Kubernetes or not - application performance is impacted by the following:
- Code efficiency
    -   Memory usage
    -   Stack depth
    -   Data structures
    -   Algorithms

- Architecture:
    - Dependency on other components
    - Caching
    - Load balancing
    - Scaling

---

## And - underneath it all
<img align="right" src="images/infra_resources.webp">
- Infrastructure Resource Availability:

    -   Storage
    -   Network
    -   Compute (cpu time)
    -   Memory

    (Finally - related to Kubernetes!)
<br clear="right"/>
--


- Let's discuss how all these infrastructure resources are managed in Kubernetes.


---
## Optimizing Kubernetes Storage

The following areas relate to storage:

- Container image storage
    -   Optimize container images ([distroless](https://github.com/GoogleContainerTools/distroless))
    -   Pre-Pull container images ([kube-fledged](https://github.com/senthilrch/kube-fledged))

- Ephemeral volumes
    - Local volumes
    - Remote volumes

- Persistent volume management

---
## Optimizing Kubernetes Networking

- The default `kube-proxy` relies on iptables and [isn't particularly fast](https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/3866-nftables-proxy/README.md#the-iptables-kernel-subsystem-has-unfixable-performance-problems)
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

- It is possible to tell kube-proxy to use [IPVS](https://kubernetes.io/docs/reference/networking/virtual-ips/#proxy-mode-ipvs)

- IPVS is a more powerful load balancing framework

(remember: iptables was primarily designed for firewalling, not load balancing!)

- It is also possible to replace kube-proxy with [kube-router](https://www.kube-router.io/)

    - kube-router uses IPVS by default

    - kube-router can also perform other functions

(e.g., we can use it as a CNI plugin to provide pod connectivity)

---

## kube-proxy with nftables

- Since v1.29 kube-proxy supports using nftables instead of the iptables and there's a [KEP](https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/3866-nftables-proxy) proposing making it the default backend for kube-proxy.

- nftables bring performance improvements over iptables, but the main motivation for this change is the gradual iptables deprecation. 

---
## Replacing kube-proxy with Cilium or Calico

- [cilium](https://cilium.io/) and [calico](https://github.com/projectcalico/calico) are Kubernetes networking solutions allowing the usage of eBPF technology

- Both cilium and calico can serve as kube-proxy replacement - providing better performance and deep network observability.

- A network performance benchmark for both can be found here:  https://cilium.io/blog/2021/05/11/cni-benchmark/

    -   It shows that eBPF is clearly superior to `iptables` but not clear if the same is true for IPVS or nftables


---
## Measuring Resources on Kubernetes

Container resource allocation and consumption on Kubernetes is collected and exposed via the Metrics Pipeline:

<img align="right" src="images/metrics-pipeline.png">

- `cAdvisor`: Daemon for collecting, aggregating and exposing container metrics included in Kubelet.

- `kubelet`: The Node agent. Resource metrics are accessible using the /metrics/resource and /stats kubelet API endpoints.

- `metrics-server`: Cluster addon component that collects and aggregates resource metrics pulled from each kubelet. The API server serves Metrics API for use by HPA, VPA, and by the kubectl top command. Metrics Server is a reference implementation of the Metrics API.

<br clear="right"/>

---

## Exploring the cAdvisor metrics

- The full cAdvisor metrics are acessible via the api server

- Let's see what is available:

.lab[
```bash
NODE1=$(kubectl get node -ojsonpath="{ .items[].metadata.name }")
kubectl get --raw "/api/v1/nodes/${NODE1}/proxy/metrics/cadvisor"
```    
]

---

## Exploring the cAdvisor metrics

Example metrics:

CPU shares for metrics-server container: 
```
container_spec_cpu_shares{container="metrics-server",id="/kubepods/burstable/pod3ab43f28-1fc6-45ed-aa4f-6947bf2a0229/b9fb4781d26005e7286ff65eb0c0952895c912e50e7fc9b0fbc26b181ba7c4c2",
image="docker.io/rancher/mirrored-metrics-server:v0.7.0",
name="b9fb4781d26005e7286ff65eb0c0952895c912e50e7fc9b0fbc26b181ba7c4c2",
namespace="kube-system",pod="metrics-server-557ff575fb-7xmzc"} 80

```

Machine CPU cores:
```
 # HELP machine_cpu_cores Number of logical CPU cores.
 # TYPE machine_cpu_cores gauge
machine_cpu_cores{boot_id="b040eebf-d137-452c-a45b-8919cfcec5d7",
machine_id="",system_uuid=""} 8

```

---


## Exposing Metrics in Cluster (and outside)

- We could use a SAAS like Datadog, New Relic...

- We could use a self-hosted solution like Prometheus

- Or we could use `metrics-server`

- What's special about `metrics-server`?

---

## Pros/cons

Cons:

- no data retention (no history data, just instant numbers)

- only CPU and RAM of nodes and pods (no disk or network usage or I/O...)

Pros:

- very lightweight

- doesn't require storage

- used by Kubernetes autoscaling

---

## Why metrics-server

- We may install something fancier later

  (think: Prometheus with Grafana)

- But metrics-server will work in *minutes*

- It will barely use resources on our cluster

- It's required for autoscaling anyway

---

## Install the metrics server

- Apply the installation yaml
.lab[
```bash  
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
]

- Verify
.lab[
```bash
  kubectl top node
```
]

---

## How metric-server works

- It runs a single Pod

- That Pod will fetch metrics from all our Nodes

- It will expose them through the Kubernetes API aggregation layer

  (we won't say much more about that aggregation layer; that's fairly advanced stuff!)


---

## Exploring the Metrics API

Once `metrics-server` is added to the cluster - CPU and memory usage for the nodes and pods in your cluster becomes accessible through the API server. Its primary role is to feed resource usage metrics to K8s autoscaler components. But we can of course use it directly.

.lab[
```bash
export NODE0=$(kubectl get node -ojsonpath="{ .items[0].metadata.name }")
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes/$NODE0" | jq

```    
]

The resulting JSON is a part of what we get in `kubectl top node`

.lab[
```bash
kubectl top node $NODE0
```
]
---
## Exploring the Metrics API

Let's try the same for pods

.lab[
```bash
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods" | jq

```    
]

The resulting JSON is a part of what we get in `kubectl top pod`

.lab[
```bash
kubectl top pod -A
```
]

---

## Keep some padding

- The RAM usage that we see should correspond more or less to the [Resident Set Size](https://en.wikipedia.org/wiki/Resident_set_size)

- Our pods also need some extra space for buffers, caches...

- Do not aim for 100% memory usage!

- Some more realistic targets:

  50% (for workloads with disk I/O and leveraging caching)

  90% (on very big nodes with mostly CPU-bound workloads)

  75% (anywhere in between!)

---

## Other tools

- kube-capacity is a great CLI tool to view resources

  (https://github.com/robscott/kube-capacity)

- It can show resource and limits, and compare them with usage

- It can show utilization per node, or per pod

- kube-resource-report can generate HTML reports

  (https://codeberg.org/hjacobs/kube-resource-report)

