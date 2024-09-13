# PWRU-kube-tracer

This project is designed to create a local deployment for existing pods in a namespace to observe traffic at that pod IP and a specific port address.

Objectively, this deployment of pods is designed to scrape all kernel traffic calls to the pod so we can observe where on the host we are losing packets originating from kubelet health probes that are not arriving at the pod.

The deployment will create for a target namespace, a dedicated pwru-* pod for each pod name in the namespace, and monitor all traffic for said pods at the pod IP and specific port (default 8080) for healthprobe testing.

The pod will create a bundle of logs locally at /tmp/${target-pod-IP}.log which can be extracted for analysis later. This log will grow until the container is killed - it is not designed for long-term deployment or analysis.

The pod will inject the date/time into the log output for reference every second, as the container trace timestamp has been determined to be unreliable/hard to reconcile when logs are continuous.

You can use the following options with the ./deploy.sh script:

`./deploy.sh` (no options) - scales pods for your specified namespace (update the script before running)

`./deploy.sh --cleanup` - deletes all pwru containers from the namespace

`./deploy.sh --pull-logs` - extracts the log bundle from each pod as a tarball to be analyzed externally. 