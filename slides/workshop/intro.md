# Introduction

First - a disclaimer!

*Performance* in software is a very elusive concept.

How do **you** define performance?

---
## Performance Metrics

- Throughput?

--

- Latency ?

--

- Resource utilization?

--

- Mean or 99th Percentile?

--

- Business Metrics?

---

## Additional Concerns
Performance in information systems is inseparable from such concerns as **cost** and **reliability** (r9y).

Therefore - when discussing how to tune our Kubernetes workloads for performance we'll also be looking at optimizing for cost and r9y.

While doing so we'll mostly focus on tuning resource allocation and utilization to hit the specific performance goals we've defined.


---

## Control Plane vs. Data Plane 

<img align="right" src="images/control-vs-data.png">

Most of the workshop is dedicated to optimizing the performance and cost of the workloads that Kubernetes orchestrates (the data plane).

We may dedicate some time in the end to discussing optimizing the performance of the control plane too.

<br clear="right"/>


