## Kubernetes Performance Foundations

In this workshop we will be looking at optimizing the performance of applications running in a Kubernetes cluster.

Kubernetes or not - application performance is impacted by the following:
- Code efficiency
    -   Memory usage
    -   Stack depth
    -   Data structures
- Infrastructure Resource Availability:
    -   Compute (cpu time)
    -   Memory
    -   Network
    -   Storage (disk I/O)

---
## Measuring Resources on Kubernetes

Container resource allocation and consumption on Kubernetes is collected and exposed via the Metrics Pipeline:

<img align="right" src="images/metrics-pipeline.png">

- cAdvisor: Daemon for collecting, aggregating and exposing container metrics included in Kubelet.

- kubelet: The Node agent. Resource metrics are accessible using the /metrics/resource and /stats kubelet API endpoints.

- metrics-server: Cluster addon component that collects and aggregates resource metrics pulled from each kubelet. The API server serves Metrics API for use by HPA, VPA, and by the kubectl top command. Metrics Server is a reference implementation of the Metrics API.

<br clear="right"/>