# The Horizontal Pod Autoscaler

- What is the Horizontal Pod Autoscaler, or HPA?

- It is a controller that can perform *horizontal* scaling automatically

- Horizontal scaling = changing the number of replicas

  (adding/removing pods)

- Vertical scaling = changing the size of individual replicas

  (increasing/reducing CPU and RAM per pod)

- Cluster scaling = changing the size of the cluster

  (adding/removing nodes)

---

## Principle of operation

- Each HPA resource (or "policy") specifies:

  - which object to monitor and scale (e.g. a Deployment, ReplicaSet...)

  - min/max scaling ranges (the max is a safety limit!)

  - a target resource usage (e.g. the default is CPU=80%)

- The HPA continuously monitors the CPU usage for the related object

- It computes how many pods should be running:

  `TargetNumOfPods = ceil(sum(CurrentPodsCPUUtilization) / Target)`

- It scales the related object up/down to this target number of pods

---

## Pre-requirements

- The metrics server needs to be running

  (i.e. we need to be able to see pod metrics with `kubectl top pods`)

- The pods that we want to autoscale need to have resource requests

  (because the target CPU% is not absolute, but relative to the request)

- The latter actually makes a lot of sense:

  - if a Pod doesn't have a CPU request, it might be using 10% of CPU...

  - ...but only because there is no CPU time available!

  - this makes sure that we won't add pods to nodes that are already resource-starved

---

## Testing the HPA

- We will start a CPU-intensive web service

- We will send some traffic to that service

- We will create an HPA policy

- The HPA will automatically scale up the service for us

---

## A CPU-intensive web service

- Let's use `otomato/busyhttp`

  (it is a web server that will use 1s of CPU for each HTTP request)

.exercise[

- Deploy the web server:
  ```bash
  kubectl create deployment busyhttp --image=otomato/busyhttp
  ```

- Expose it with a ClusterIP service:
  ```bash
  kubectl expose deployment busyhttp --port=80
  ```


]

---

## Monitor what's going on

- Let's start a bunch of commands to watch what is happening

.exercise[

- Monitor pod CPU usage:
  ```bash
  watch kubectl top pods -l app=busyhttp
  ```

  - Start a network testing container and monitor service latency:
  ```bash
  kubectl run netutils --image=otomato/net-utils "ping localhost"
  kubectl exec netutils httping http://busyhttp/
  ```


- Monitor cluster events:
  ```bash
  kubectl get events -w
  ```

]

---

## Send traffic to the service

- We will use `ab` (Apache Bench) to send traffic

.exercise[

- Send a lot of requests to the service, with a concurrency level of 3:
```bash
  kubectl exec netutils -- ab -c 3 -n 100000 http://busyhttp/
  ```

]

The latency (reported by `httping`) should increase above 3s.

The CPU utilization should increase to 100%.

(The server is single-threaded and won't go above 100%.)

---

## Create an HPA policy

- There is a helper command to do that for us: `kubectl autoscale`

.exercise[

- Create the HPA policy for the `busyhttp` deployment:
  ```bash
  kubectl autoscale deployment busyhttp --max=10
  ```

]

By default, it will assume a target of 80% CPU usage.

This can also be set with `--cpu-percent=`.

--

*The autoscaler doesn't seem to work. Why?*

---

## What did we miss?

- The events stream gives us a hint, but to be honest, it's not very clear:

  `missing request for cpu`

- We forgot to specify a resource request for our Deployment!

- The HPA target is not an absolute CPU%

- It is relative to the CPU requested by the pod

---

## Adding a CPU request

- Let's edit the deployment and add a CPU request

- Since our server can use up to 1 core, let's request 1 core

.exercise[

- Edit the Deployment definition:
  ```bash
  kubectl edit deployment busyhttp
  ```

- In the `containers` list, add the following block:
  ```yaml
    resources:
      requests:
        cpu: "1"
  ```

]

---

## Results

- After saving and quitting, a rolling update happens

  (if `ab` or `httping` exits, make sure to restart it)

- It will take a minute or two for the HPA to kick in:

  - the HPA runs every 30 seconds by default

  - it needs to gather metrics from the metrics server first

- If we scale further up (or down), the HPA will react after a few minutes:

  - it won't scale up if it already scaled in the last 3 minutes

  - it won't scale down if it already scaled in the last 5 minutes

---
## Cleanup

- Since `busyhttp` pods use CPU cycles, let's delete them before moving on

.exercise[

- Stop `ab` and `httping` processes

- Delete the `busyhttp` pods:
  ```bash
  kubectl delete pod -lapp=busyhttp
  ```
]

The new pods won't consume CPU, so after 5 minutes the HPA will scale the deployment down.

---
## What about other metrics?

- The HPA in API group `autoscaling/v1` only supports CPU scaling

- The HPA in API group `autoscaling/v2` supports metrics from various API groups:

  - metrics.k8s.io, aka metrics server (per-Pod CPU and RAM)

  - custom.metrics.k8s.io, custom metrics per Pod

  - external.metrics.k8s.io, external metrics (not associated to Pods)

- Kubernetes doesn't implement any of these API groups

- Using these metrics requires [registering additional APIs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-metrics-apis)

- The metrics provided by metrics server are standard; everything else is custom

- For more details, see [this great blog post](https://medium.com/uptime-99/kubernetes-hpa-autoscaling-with-custom-and-external-metrics-da7f41ff7846) or [this talk](https://www.youtube.com/watch?v=gSiGFH4ZnS8)

---

## Exercise - Scaling on Memory

.exercise[
- Memory-based autoscaling is supported in autoscaling/v2

- The metrics for memory are available from the metrics-server we already have in the cluster

- Let's edit our HPA:
  ```bash
  kubectl edit hpa busyhttp
  ```

]

---

## Add memory utilization target

.exercise[
  Add the following in the HPA yaml:
  ```yaml
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  ```
]

---

## Define memory requests

- Just as with CPU - we need to define the requests for the HPA to work

- Let's edit the deployment and add a memory request for 70Mb

.exercise[

- Edit the Deployment definition:
  ```bash
  kubectl edit deployment busyhttp
  ```

- In the `containers` list, add the following block:
  ```yaml
    resources:
      requests:
        memory: "70M"
  ```
]

---

## Test The HPA

- `busyhttp` can also load memory. It consumes 1Mb of memory for each request to `/memory` endpoint

.exercise[
- Run 5 requests to /memory endpoint
  ```bash
  kubectl exec netutils -- httping -c 3 http://$CLUSTERIP/memory
  ```

- Memory consumption should go up to 40Mb from the original 35Mb
  ```bash
  kubectl top pods -l app=busyhttp
  ```
]

---
## Load the memory to cause HPA to scale

.exercise[
- Load memory to more than 80% by calling `httping` or `ab`

- Watch HPA scale out 

- Free memory by calling the `/memfree` endpoint of `busyhttp` 

  ```bash
  kubectl exec netutils -- ab -c 3 -n 1000 http://$CLUSTERIP/memfree
  ```

- Watch HPA scale down after 5 minutes.

]