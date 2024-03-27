[[_TOC_]]

# Summary

`Wiz Runtime Sensor` is a small ebpf (Extended Berkeley Packet Filter) agent deployed on every Kubernetes Node, meticulously monitoring system calls to pinpoint suspicious activities. It proactively identifies and alerts on behaviors that look malicious, signaling potential security threats or anomalies. The Wiz Sensor operates by leveraging a set of rules that define which system call sequences and activities are deemed abnormal or indicative of security incidents.

# Monitoring/Alerting

The most likely issue deriving from the Wiz Rutime Sensor rollout might be related to an eventual performance penalty on the underlying kubernetes cluster nodes.

However it should not create much performance implications as we have configured the limits which are very resource convervative. We have the CPU and Memory limits configured and those can be viewed [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/wiz-sensor/values.yaml.gotmpl?ref_type=heads#L13).

In addition, an [alert for OOM kills](https://gitlab.com/gitlab-com/runbooks/-/blob/master/rules/wiz-runtime-sensor.yml) for Wiz Sensor containers which would help us understand if the resource consumption is more and if the sensor are getting OOM killed.

# Service Managment

## Deploy Wiz Runtime Sensor

All of our workload deployments are taken care of from the [GitLab helm repo](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles).

To deploy it for different environments we need to only add the values to the environments files ({$env}.yaml) located [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/bases/environments)

For the sample deployment, we can review the deployment for the pre-environment [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/bases/environments/pre.yaml?ref_type=heads#L129-131)

```json
wiz-sensor:
  installed: true
  chart_version: x.x.x.x

```

## Disable Wiz Runtime Sensor

**Note: Before disabling the Wiz Runtime Sensor we have to update the compliance team to track the GAP in coverage. Create the issue to disable the Wiz Sensor and tag `@gitlab-com/gl-security/security-assurance/team-commercial-compliance` team.**

All of our workload deployments are taken care of from the [Gitlab helm repo](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles).

To remove/disable the sensor we need to follow the below steps.

1. Navigate to the environments folder [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/bases/environments)

1. Open the file for the specific environment, naming syntax for the file is {$env-name}.yaml.

1. Navigate to the code block that has the root key as `wiz-sensor`, and that the installed value from `true` to `false`. After the change, it should be as shown in the below snippet.

    ```json
    wiz-sensor:
      installed: false
      chart_version: x.x.x.x
    ```

# Troubleshooting

<!--Import from Wiz Doc Starts here -->
## Verify the Runtime Sensor is installed and running

Start any investigation by first verifying that the Runtime Sensor is installed on your cluster, and checking its current status.
Verify the Runtime Sensor is deployed

Run the following command to verify the Runtime Sensor is deployed as a DaemonSet on your cluster:

```shell
kubectl get ds -n wiz
```

Below is the expected output:

```console
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
wiz-sensor   6         6         6       6            6           <none>          24d
```

Inspect the output:

- If your output is as expected, continue to the other scenarios listed on this page to locate your problem.
- If you do not see a similar output, it could indicate something went wrong with the Runtime Sensor installation. Refer back to the installation guide to verify proper installation, and to perform a sanity check.

## Check the Runtime Sensor status

Run the following command to check the status of all the Runtime Sensors in your cluster:

```shell
kubectl get pods -n wiz -l "app.kubernetes.io/name=wiz-sensor"
```

Below is the expected output:

```console
NAME               READY   STATUS    RESTARTS        AGE
wiz-sensor-2gqv2   1/1     Running   181 (12m ago)   24d
wiz-sensor-989vj   1/1     Running   179 (11m ago)   24d
wiz-sensor-kv22v   1/1     Running   178 (16m ago)   24d
wiz-sensor-r8bw8   1/1     Running   177 (11m ago)   24d
wiz-sensor-rw27j   1/1     Running   182 (12m ago)   24d
wiz-sensor-wccbk   1/1     Running   180 (12m ago)   24d
```

Inspect the output:

- If a Runtime Sensor pod is in Pending status, then the underlying node does not have enough resources to run the pod (see resource consumption for all details). Once some node resources are free, the Sensor pod status should automatically change to Running.

- If one or more Runtime Sensor pods are neither in Running nor Pending status, refer to the Runtime Sensor is not running troubleshooting procedure below.

## Check the Runtime Sensor version

You can retrieve the version number directly from a specific running Runtime Sensor pod:

Use the following kubectl command. Replace <pod name> with the name of the running Runtime Sensor pod. This command will execute the Runtime Sensor binary within the pod and display its version:

```shell
kubectl exec -it -n wiz <pod name> -- /usr/src/app/wiz-sensor version
```

Review the output. You can see the Runtime Sensor version, including the build number and the build time. You can also see the version of the Runtime Sensor definitions file, which contains the detection rules and configurations used by the Runtime Sensor:

```console
2023-05-18T06:34:31.679826Z  INFO client version: 0.9.1869 (CMT_cafa988 2023-04-24T18:56:49+03:00)
2023-05-18T06:34:31.679855Z  INFO server version: 0.9.1869 (CMT_cafa988 2023-04-24T18:56:49+03:00) (definitions: 1.0.609)
```

Identify what is the latest Sensor version from the Sensor Release Notes. If you are running an older version, consider upgrading it.

## The Runtime Sensor is not running

When a Runtime Sensor pod is not in Running status, it could indicate that the Runtime Sensor image was not pulled successfully.

Verify the Runtime Sensor container image was pulled successfully

If the Runtime Sensor pod status is ImagePullBackOff or ErrImagePull, it may mean Kubernetes could not pull the Runtime Sensor container image from wizio.azurecr.io.

Run the following command to list all pods in the cluster and their statuses:

```shell
kubectl -n wiz describe pods -l "app.kubernetes.io/name=wiz-sensor"
```

Below is the expected output for a successful Runtime Sensor installation:

```console
Events:
  Type    Reason   Age                  From     Message
  ----    ------   ----                 ----     -------
  Normal  Pulled   46m                  kubelet  Successfully pulled image "wizio.azurecr.io/sensor:preview" in 114.84398ms
  Normal  Pulling  36m (x181 over 24d)  kubelet  Pulling image "wizio.azurecr.io/sensor:preview"
  Normal  Created  36m (x181 over 24d)  kubelet  Created container wiz-sensor
  Normal  Started  36m (x181 over 24d)  kubelet  Started container wiz-sensor
  Normal  Pulled   36m                  kubelet  Successfully pulled image "wizio.azurecr.io/sensor:preview" in 103.217499ms
```

Inspect the output and search for any errors in the Message column. If you detect errors related to pulling the image, such as ImagePullBackOff or ErrImagePull, check the following:

- There is outbound connectivity to "wizio.azurecr.io"
- The correct credentials were used to pull the container image

## There is outbound connectivity to "wizio.azurecr.io"

Run the following command that downloads a popular curl container image:

```shell
kubectl run networkcheck --image=curlimages/curl -it --rm --restart=Never --overrides='{"apiVersion": "v1", "spec": {"hostNetwork": true}}' -- curl -I https://wizio.azurecr.io/v2/
```

Below is the expected output when there is working communication with "wizio.azurecr.io":

```console
HTTP/1.1 401 Unauthorized
Server: openresty
Date: Sun, 09 Apr 2023 14:29:48 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 149
Connection: keep-alive
Access-Control-Expose-Headers: Docker-Content-Digest
Access-Control-Expose-Headers: WWW-Authenticate
Access-Control-Expose-Headers: Link
Access-Control-Expose-Headers: X-Ms-Correlation-Request-Id
Docker-Distribution-Api-Version: registry/2.0
Strict-Transport-Security: max-age=31536000; includeSubDomains
Www-Authenticate: Bearer realm="https://wizio.azurecr.io/oauth2/token",service="wizio.azurecr.io"
...
```

Inspect the output:

- If your output is as expected, continue to verify the correct credentials were used to pull the container image.

- If your output differs from the expected output (for example, you see a Connection refused error), then your cluster does not have outbound connectivity to "wizio.azurecr.io". To resolve this:

- Check any network configurations that might block outbound connections (e.g., firewall rules, proxy configurations, Kubernetes network policies) and allow the connectivity to "wizio.azurecr.io".

- Re-install the Runtime Sensor.

The correct credentials were used to pull the container image

## Verify you installed the Runtime Sensor using the correct credentials to pull the container image

- Retrieve the values you used for imagePullSecret.username and imagePullSecret.password, in either the helm install command or the YAML file.

- Refer to get the Runtime Sensor image pull key from wiz to obtain the correct values that should be used for imagePullSecret.username and imagePullSecret.password.

Compare the set of values.

- If the credentials used in the installation are not identical to the ones you retrieved from the Wiz portal:
  - Update the values in your helm install command or yaml file.
  - Re-install the Runtime Sensor using the new values.

- If the credentials are identical but your pods are not in Running or Pending status, please contact support.

## Verify the Kubernetes nodes have enough resources to run the Runtime Sensor

If some of the pods are in an error state, that could indicate that their corresponding node lacks the required resources needed to run the Sensor pod. These cases are usually resolved once the nodes have enough resources and there is no need for intervention.

Run the following command to locate Sensor pods that are not running:

```shell
kubectl get pods --field-selector=status.phase!=Running -n wiz
```

The output should return the Sensor pod names. For example:

```console
NAME               READY   STATUS   RESTARTS   AGE
wiz-sensor-99fx4   0/1     Error    0          9m29s
wiz-sensor-v96pp   0/1     Error    0          9m29s
```

Run the following command to get all Kubernetes events related to the Sensor pod. Replace <pod-name> with a pod name from the output of the previous command:

```shell
kubectl get events -n wiz | grep <pod-name>
```

The output should indicate the reason for the error. For example, line 6 of the following output indicates that the Sensor pod is not running since the node does not have enough free memory:

    ```console
    6m58s       Normal    Scheduled          pod/wiz-sensor-zx2xk   Successfully assigned wiz/wiz-sensor-zx2xk to ip-192-168-3-61.ec2.internal
    6m57s       Normal    Pulling            pod/wiz-sensor-zx2xk   Pulling image "wizio.azurecr.io/sensor:preview"
    6m57s       Normal    Pulled             pod/wiz-sensor-zx2xk   Successfully pulled image "wizio.azurecr.io/sensor:preview" in 138.135823ms
    6m57s       Normal    Created            pod/wiz-sensor-zx2xk   Created container wiz-sensor
    6m57s       Normal    Started            pod/wiz-sensor-zx2xk   Started container wiz-sensor
    6m46s       Warning   Evicted            pod/wiz-sensor-zx2xk   The node was low on resource: memory. Container wiz-sensor was using 80404Ki, which exceeds its request of 50Mi.
    6m46s       Normal    Killing            pod/wiz-sensor-zx2xk   Stopping container wiz-sensor
    ```

## The Runtime Sensor does not appear on the Deployments page

When you verify the Runtime Sensor pod is running but it does not appear on the Settings > Deployments > Sensor page in the Wiz portal, it indicates there is a communication error between the Sensor and your Wiz tenant.

Run the following command to see any Runtime Sensor communication errors:

```shell
kubectl -n wiz logs $(kubectl get pods -n wiz -l "app.kubernetes.io/name=wiz-sensor" -o jsonpath="{.items[0].metadata.name}") | grep -i auth
```

According to the output, proceed to one of the following use cases:

- Invalid TLS/SSL certificate
- Invalid service account type (status code 400)
- Invalid credentials (status code 401)
- Service Account token is not mounted

### Invalid TLS/SSL certificate

Displayed error

```console
{... , invalid peer certificate contents: invalid peer certificate: UnknownIssuer"}}
```

This error indicates the Runtime Sensor cannot validate the TLS certificate of the remote server.

**What you should do ?**

Often the validation fails due to incorrect proxy settings. To fix the settings, you need to update the fields listed below in your Runtime Sensor helm chart. Refer to Runtime Sensor configurable variables to learn how.

```console
daemonset.httpProxyUrl
daemonset.httpProxyUsername
daemonset.httpProxyPassword
daemonset.httpProxyCaCert
```

### Invalid service account type (status code 400)

Displayed error

```console
{... ,"fields":{"message":"comm error","e":"https://auth.app.wiz.io/oauth/token: status code 400"}}
```

This error indicates the Runtime Sensor service account type is not configured properly in the Runtime Sensor helm chart.

For security reasons, the Runtime Sensor uses a special service account type, which is incompatible with the regular (GraphQL) service accounts.

**What you should do?**

Set the proper service account type wizApiToken.clientId and wizApiToken.clientToken helm chart values. Refer to Create a service account for the Runtime Sensor to learn how.
Re-install the Runtime Sensor using the new values.

### Invalid credentials (status code 401)

Displayed error

```console
{... ,"fields":{"message":"comm error","e":"https://auth.app.wiz.io/oauth/token: status code 401"}}
```

This error indicates the credentials to the Wiz Portal are not configured properly in the Runtime Sensor helm chart.

**What you should do?**

Run the following command to query your Kubernetes cluster which credentials were used for the Runtime Sensor installation, specifically wizApiToken.clientId and wizApiToken.clientToken (and in rare cases also wizApiToken.clientEndpoint):

The following kubectl commands apply to the built-in Kubernetes Secrets objects. If you are using another external secret management tool, learn how to troubleshoot authentication errors using Sensor logs in order to reveal the actual secret content.

```shell
kubectl -n wiz get secrets wiz-sensor-apikey -o jsonpath="{.data}" | jq -r '.clientId | @base64d'
kubectl -n wiz get secrets wiz-sensor-apikey -o jsonpath="{.data}" | jq -r '.clientSecret | @base64d'
```

Refer to create a service account for the Runtime Sensor to obtain the correct values that should be used.

Compare the set of values

If you used different values, update them and Re-install the Runtime Sensor using the new values.

If you used the correct values, contact support as explained below.

### Service Account token is not mounted

Displayed error

```console
"message": "sensor engine failed to start",
    "e": "init kube version\n\nCaused by:\n    0: reading cluster env\n    1: failed to read the default namespace: No such file or directory (os error 2)\n    2: No such file or directory (os error 2)",
```

This error indicates that service account token mounting is disabled.

**What you should do?**

Check the service account used.

```shell
kubectl get ds -n wiz wiz-sensor -o json | jq . | grep serviceAccount
```

Check if service account token mount is disabled.

```shell
kubectl get sa -n wiz <insert-service-account> -o yaml
```

If you see automountServiceAccountToken=false, service account token mount is disabled. It should be set to true or removed.

## Communication-related errors

If there are temporary connectivity problems, the Runtime Sensor uses a retry mechanism to resolve this. Let's look for example at a DNS resolution error.

### DNS resolution error

Assuming this error persists:

"dns error: failed to lookup address information: Temporary failure in name resolution"

- Check your DNS settings.
- Verify that the namespace where you deployed the Runtime Sensor has "DNS enabled". You can check the DNS resolution using a curl command:

```shell
kubectl run -n wiz networkcheck --image=curlimages/curl -it --rm --restart=Never --overrides='{"apiVersion": "v1", "spec": {"hostNetwork": true}}' -- curl -I https://wizio.azurecr.io/v2/
```

If there is a DNS problem, you will get this error code from curl:

```console
curl: (6) Could not resolve host: localhost
curl: (6) Could not resolve host: wizio.azurecr.io
```

Once the DNS issue is resolved, the Sensor should recover from the error.

### Connection reset by peer error

The following error message might indicate that there is a firewall blocking the communication to `https://auth.app.wiz.io`:

`https://auth.app.wiz.io/oauth/token`: Connection Failed: tls connection init failed: Connection reset by peer (os error 104)

Use the curl command in order to verify that the connection is blocked:

```shell
kubectl run -n wiz networkcheck --image=curlimages/curl -it --rm --restart=Never --overrides='{"apiVersion": "v1", "spec": {"hostNetwork": true}}' -- curl -I https://auth.app.wiz.io/oauth/token
```

Once the firewall (or any other network component that is blocking the connection) is configured to allow it, the Runtime Sensor should recover from the error.

The Runtime Sensor is installed on an unsupported platform.

If the Runtime Sensor is installed on an unsupported platform, such as an incompatible kernel version, the Runtime Sensor pod will run but the Sensor binary will fail to execute.

To verify if this is the case,

Search the logs using the following command:

```shell
kubectl logs -n wiz <pod name> | grep "sensor engine failed to start"
```

Search for the following error message:

kernel version smaller than minimum 266752

In this case, check the Supported Architectures and Platforms documentation to ensure that your platform is supported. If your platform is listed as supported, reach out to our support team using the instructions provided below.

### Verify the node architecture is supported

Displayed error

exec ./wiz-sensor: exec format error

This error means that the Sensor is running on a non-supported architecture, or that the Sensor image does not match the node architecture.

**What you should do?**

Check the node architecture using the following command:

```shell
kubectl describe nodes <node name> | grep Architecture
```

The output should be one of the supported architectures, amd64 or arm64. If the architecture is supported and yet you still encounter this error, it could indicate that the Sensor image does not match the underlying architecture.

Generally, when you use Docker to pull the Sensor image, it will detect the underlying host architecture and fetch the correct image from the Wiz registry. If you are mirroring the image to an internal repository, we recommend using tools like skopeo.

Learn how to read Runtime Sensor logs

Each Sensor pod stores only a minimal amount of logs on the local disk, consisting mainly of error messages, and sometimes also success messages. Each message is formatted in JSON and contains the variables, such as:

```console
timestamp–Time of the log message.
binary_ver–Sensor version number.
defs_ver–Definitions file version.
message–The log message.
level–The log level. By default, local Sensor logs include only messages where level=ERROR and a small amount of informational logs where level=INFO.
```

Below is an example error log message:

```console
{
  "timestamp": "2023-06-15T09:43:52.126652379+00:00",
  "level": "ERROR",
  "target": "sensor::comm::auth",
  "filename": "engine/src/comm/auth.rs",
  "line_number": 224,
  "sensor_metadata": {
    "defs_commit": "21ad08e",
    "k8s": {
      "k8s_pod": "wiz-sensor-zpdxc",
      "k8s_version": "1.24",
      "k8s_cluster_id": "106db0a976023989f0d7bc27d13be2c1fc9f84131f840de89f5fc31b4b5947af",
      "k8s_namespace": "wiz",
      "k8s_node_id": "k8s/node/106db0a976023989f0d7bc27d13be2c1fc9f84131f840de89f5fc31b4b5947af/ip-192-168-60-227.ec2.internal",
      "helm_version": "wiz-sensor-0.1.2",
      "k8s_pod_image": "wizio.azurecr.io/sensor:preview"
    },
    "cpu_core_count": 2,
    "ebpf_kernel_ver": "5.10.165",
    "defs_ver": "1.0.745",
    "sensor_start_time": "2023-06-15T09:43:51.387257460+00:00",
    "machine_sysname": "Linux",
    "pid": 8542,
    "machine_arch": "x86_64",
    "cloud_provider": "aws",
    "comm_client_id": "elxchgtoqfhnrd4igptg6s662tlrbhcmdy6vlbvhr5gnd75p74ngc",
    "binary_ver": "1.0.2142",
    "machine_kernel_build_time": "#1 SMP Wed Jan 25 03:13:54 UTC 2023",
    "total_memory": 4110323712,
    "machine_nodename": "ip-192-168-60-227.ec2.internal",
    "machine_kernel_ver": "5.10.165-143.735.amzn2.x86_64",
    "tenant_id": ""
  },
  "fields": {
    "message": "comm error",
    "e": "https://auth.app.wiz.io/oauth/token: status code 401"
  }
}
```

## Retrieve log messages

To obtain a summarized version of all log messages generated by the Sensor pods, where each error is displayed only once per cluster, execute the following command:

```shell
kubectl -n wiz logs daemonsets/wiz-sensor | grep ERROR | jq  '.fields.message' | sort -u
```

If you wish to view the detailed errors messages , use the following command:

```shell
kubectl -n wiz logs daemonsets/wiz-sensor | grep ERROR | jq '.fields.e' | sort -u
```

## Adjust logging verbosity

### Increasing verbosity risks

Before increasing the log verbosity, keep in mind that:

This is not recommended for production environments as it could lead to the generation of large debugging volumes / trace logs, which could impact performance and increase resource consumption.

This poses a security risk as increasing the verbosity level could expose sensitive information within your logs (such as clear text secrets).

To adjust the verbosity level of the Sensor logs,

Set the logLevel configurable variable in the Helm chart to do one of the following:

Increase the overall verbosity level–Add: --set logLevel=info.

Increase the verbosity level of a specific Sensor component–For example, to set the maximum verbosity for all messages related to Sensor authentication, set logLevel to info,sensor::comm::auth=trace.
(Recommended for production environments) Use the default verbosity level–Omit the logLevel variable altogether.

Deploy the Runtime Sensor.

## Troubleshoot authentication errors using Sensor logs

Follow the steps below to increase the verbosity level of the Sensor, which will result in the output of the credentials of the Wiz service account it is using to communicate with the Wiz backend.

If you already have a running Sensor with authentication errors, uninstall it.

Reinstall the Sensor and provide the following configurable variable to the helm install command: --set logLevel="info\,sensor::comm::auth=trace"

Upon startup, the Sensor logs will contain the secret. Use the following command to search for the log message with the credentials: kubectl logs -n wiz <POD NAME> | grep "user credentials".

The credentials for the Wiz service account username and password are printed in plain text.

Once the troubleshooting is complete, reinstall the Sensor. This time, remove the logLevel configurable variable to set the verbosity of the Sensor back to its default level.

## Restart the Runtime Sensor

To restart all running Sensor pods, run the following command:

`kubectl rollout restart -n wiz ds/wiz-sensor`

Contact support

If none of the scenarios above match your case, please contact support:

Create a support package for the Runtime Sensor
Contact Wiz support and include the support package.

## Create a support package for the Runtime Sensor

The following script executes various troubleshooting commands and saves the output to an archive named k8s_outputs.tar.gz. Please attach this file when contacting Wiz support.

To run the script:

Copy the following script

```shell
#!/bin/bash

# Use the NS variable to set the namespace where the wiz sensor is deployed (the default should be "wiz")
NS=wiz  # Change this if you are using a different namespace name for the wiz sensor

# Create a directory to store the output files
mkdir k8s_outputs

# Execute kubectl commands and store their outputs in separate files
kubectl get ds -n $NS -o yaml &> k8s_outputs/ds.yaml

kubectl get pods -n $NS -l "app.kubernetes.io/name=wiz-sensor" -o yaml &> k8s_outputs/pods.yaml

kubectl get nodes -o yaml &> k8s_outputs/nodes.yaml

SENSOR_SA_NAME=$(kubectl get pods -n $NS -l "app.kubernetes.io/name=wiz-sensor"  -o jsonpath="{.items[0].spec.serviceAccount}")
kubectl get clusterrole $SENSOR_SA_NAME -o yaml &> k8s_outputs/clusterrole.yaml

kubectl get clusterrolebinding $SENSOR_SA_NAME -o yaml &> k8s_outputs/clusterrolebinding.yaml

kubectl get role -n $NS -l "app.kubernetes.io/name=wiz-sensor" -o yaml &> k8s_outputs/role.yaml

kubectl get rolebinding -n $NS -l "app.kubernetes.io/name=wiz-sensor" -o yaml &> k8s_outputs/rolebinding.yaml

kubectl describe pods -n $NS -l "app.kubernetes.io/name=wiz-sensor" &> k8s_outputs/pod_description.txt

kubectl get secrets -n $NS -o yaml &> k8s_outputs/secrets.yaml

SENSOR_POD_NAME=$(kubectl get pods -n $NS -l "app.kubernetes.io/name=wiz-sensor"  -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n $NS $SENSOR_POD_NAME &> k8s_outputs/sensor_logs.txt

kubectl exec -it -n $NS $SENSOR_POD_NAME -- /usr/src/app/wiz-sensor version &> k8s_outputs/sensor_version.txt

kubectl exec -it -n $NS $SENSOR_POD_NAME -- /usr/src/app/wiz-sensor get-statistics &> k8s_outputs/sensor_statistics.txt

kubectl exec -it -n $NS $SENSOR_POD_NAME -- /usr/src/app/wiz-sensor actors &> k8s_outputs/sensor_actors.txt

kubectl exec -it -n $NS $SENSOR_POD_NAME -- /usr/src/app/wiz-sensor containers &> k8s_outputs/sensor_containers.txt

# Create a tar archive of the output files
tar -czvf k8s_outputs.tar.gz k8s_outputs

# Delete the output files outside the archive
rm -rf k8s_outputs

```

Save the script into a file named: `sensor-support.sh`

Grant permission for the file to be executed by running the following command:

```shell
chmod +x ./sensor-support.sh
```

Run the script:

```shell
./sensor-support.sh
```

The output is saved to a file named k8s_outputs.tar.gz. Attach it when contacting support.

<!--Import from Wiz Doc Ends here -->

# Links to further Documentation

- [Wiz Helm Chart](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/wiz-sensor)
- [Internal Handbook Page](https://internal.gitlab.com/handbook/security/infrastructure_security/tooling/wiz-sensor/)
