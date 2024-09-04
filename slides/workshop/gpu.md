
# Allocating GPU resources
 
Since v1.26 Kubernetes includes stable support for managing AMD and NVIDIA GPUs across different nodes in your cluster, using **device plugins**.

Principle of operation:
- install GPU drivers on the nodes
- run the corresponding device plugin from the GPU vendor

Once you have installed the plugin, your cluster exposes a custom schedulable resource such as **amd.com/gpu** or **nvidia.com/gpu**


---

## GPU Limits are Requests

GPUs are only supposed to be specified in the limits section, which means:

- You can specify GPU limits without specifying requests, because Kubernetes will use the limit as the request value by default.
- You can specify GPU in both limits and requests but these two values must be equal.
- You cannot specify GPU requests without specifying limits.

- Currently only whole GPU units are supported

- To improve utilization - vendor-specific techniques like [time-slicing](https://developer.nvidia.com/blog/improving-gpu-utilization-in-kubernetes/#time-slicing_support_in_kubernetes) need to be configured

---

## GPU Limits Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dcgmproftester-1
spec:
  restartPolicy: "Never"
  containers:
  - name: dcgmproftester11
    image: nvidia/samples:dcgmproftester-2.0.10-cuda11.0-ubuntu18.04
    args: ["--no-dcgm-validation", "-t 1004", "-d 30"]  
    resources:
      limits:
         nvidia.com/gpu: 1   # Requesting 1 CPU
```