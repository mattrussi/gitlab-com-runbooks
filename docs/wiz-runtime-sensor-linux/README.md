<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Wiz Sensor Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22wiz-runtime-sensor-linux%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Wiz Sensor"

## Logging

* []()

<!-- END_MARKER -->

<!-- ## Summary -->
# Summary

`Wiz Runtime Sensor` is a small ebpf (Extended Berkeley Packet Filter) agent deployed on every Linux Node, meticulously monitoring system calls to pinpoint suspicious activities. It proactively identifies and alerts on malicious behaviours, signalling potential security threats or anomalies. The Wiz Sensor operates by leveraging a set of rules that define which system call sequences and activities are deemed abnormal or indicative of security incidents.
<!-- ## Architecture -->
## Architecture

Can be found in the [Internal handbook](https://internal.gitlab.com/handbook/security/product_security/infrastructure_security/tooling/wiz-sensor/#architecture)
<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

# Monitoring/Alerting

The agent should not create many performance implications as the configured limits are very resource-conservative. We have the CPU and Memory limits configured

# Service Managment

## Deploy Wiz Runtime Sensor for Linux

Following are the steps to Deploy Wiz Runtime Sensor.

* Navigate to the [Chef Repo Roles](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/tree/master/roles?ref_type=heads).
* Open the role targetting a specific environment or service for which the Wiz Runtime Sensor needs to be Deployed.
* Set the Wiz Runtime Sensor `enabled` flag to `true`

   ```json
    "wiz_sensor": {
        "enabled": true,
        "secrets_source": "hashicorp_vault"
    }
   ```

Refer the [sample MR](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/4945) that was created to enable the service on the VM hosts.

## Disable Wiz Runtime Sensor for Linux

**Note: Before disabling the Wiz Runtime Sensor we have to update the compliance team to track the GAP in coverage. Create the issue to disable the Wiz Sensor and tag `@gitlab-com/gl-security/security-assurance/team-commercial-compliance` team.**

In case any performance or any other issues observed with Wiz Runtime Sensor for Linux and it is impact the production we can always disable it.

Following are the steps to disable Wiz Runtime Sensor.

* Navigate to the [Chef Repo Roles](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/tree/master/roles?ref_type=heads).
* Open the role targetting specific environment or service for which the Wiz Runtime Sensor needs to be disabled.
* Set the Wiz Runtime Sensor `disable_service` flag to `true`

   ```json
    "wiz_sensor": {
        "disable_service": true
    }
   ```

Refer the [sample MR](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/4945) that was created to stop the service on the VM hosts.

<!--Import from Wiz Doc Starts here -->

## Working with logs

The Linux Runtime Sensor stores error logs and some informational logs on the host machine. When you start any investigation, you should first review the logs to verify the Sensor can communicate with the Wiz backed.

The following commands can be used on a typical Linux host.

To access the logs folder and view its contents, you need root permissions. Switch to root use by running:

`sudo su`

Then, navigate to the Sensor logs folder by running:

`sudo cd /opt/wiz/sensor/host-store/sensor_logs`

Verify that the Sensor can communicate with the Wiz backend by running:

`sudo cat /opt/wiz/sensor/host-store/sensor_logs/sensor.log | grep "content update"`

When the Sensor installation is successful and communication exists, you should see the following message:

```
{...,"fields":{"message":"ending content update - no new content available"}}
```

If you do not see this message, read on to learn what is wrong and how you can fix it.

## Understanding common errors

Below is a list of some common Sensor errors and what they mean.,

Not all error messages are considered fatal. If you encounter an error that is not documented and your Sensor is operating properly (i.e. appears Active on the Setting > Deployments page), you can safely ignore the error.

Start by obtaining a summarized version of all error log messages by running the following command:

```
sudo cat /opt/wiz/sensor/host-store/sensor_logs/sensor.log | grep ERROR | jq -r '"\(.fields.message), \(.fields.resp)"' | sort -u
```

The table below lists common errors and how to resolve them:

| Error Message | Explanation |
| --- | --- |
| comm error (400) | Invalid service account type. Indicates that the Wiz service account you are using is not of type `Sensor`. |
| comm error (401) | Invalid credentials in the install script. <br><br>Make sure you provided the WIZ_API_CLIENT_ID and WIZ_API_CLIENT_SECRET environment variables. |
| Connection Failed: tls connection init failed | This could be caused by a firewall that is blocking the communication to Wiz. Verify there is connectivity by running the following command:<br><br>`curl -I https://auth.app.wiz.io/oauth/token` |
| dns error | This could be a temporary issue. If it persists, check that there is outbound connectivity to  `auth.app.wiz.io` by running the following command:<br><br>`curl -I https://auth.app.wiz.io` |
| failed loading ebpf skeleton | There is policy that restricts the usage of eBPF.  This could be caused by a SELinux policy. |
| invalid peer certificate contents | The Sensor could not validate the TLS certificate of the remote server. make sure you provided the WIZ_HTTP_PROXY_CERT or WIZ_EXTRA_SSL_CERT_DIR environment variables. |

## Troubleshooting the installation script and downloader

### Installation script

The installation script (sensor_install.sh) returns a zero exit code upon successful execution, and a non-zero value for any of the following scenarios:

* Outdated kernel
* Invalid Wiz API key
* Unsupported Linux distribution
* Incompatible system architecture
* Execution by non-root user
* Incompatible environment variables provided (e.g. enabling auto-update while also adding a specific version)
* Installation failure (e.g. inability to create directories or add packages to the package manager)
* No outbound connectivity to the required domains (e.g. rpm.wiz.io, dpkg.wiz.io, downloads.wiz.io)

### Downloader

The installation script utilizes your native package manager (yum/apt) to install the Sensor downloader. This downloader then connects to the Wiz backend, using the provided credentials, in order to download the Sensor binary and install it on the machine.

The downloader logs format is identical to the Sensor logs format (json messages with either an INFO or ERROR level).

Access the downloader logs folder and view its contents by running:

sudo cd /opt/wiz/sensor/host-store/downloader_logs

Obtain a summarized version of all error log messages by running the following command:

```
sudo cat /opt/wiz/sensor/host-store/downloader_logs/downloader.log | grep ERROR | jq  '.fields.message' | sort -u
```

If the Sensor installation was successful, you should not see any ERROR messages in the downloader logs.

## Troubleshooting Linux issues

### SELinux policy

When you have an SELinux policy that prevents the Sensor from running (usually due to a policy that restricts the use of bpf), you will see an error message such as:

`"e":"failed loading ebpf skeleton\n\nCaused by:\n    System error, errno: 13 (EACCES: Permission denied)"`

To verify that this is the case and that the SELinux is the one preventing the Sensor for working:

1. Temporarily disable SELinux using the command: `setenforce 0`.
2. Restart the Sensor ([Steps](#how-to-restart-the-linux-sensor)).
3. Verify the Sensor is running successfully.

After you've established that your SELinux policy is causing the problem, you need to modify it to allow the Sensor to interact with BPF. Since the Sensor runs as `unconfined_service_t`, you need to allow `unconfined_service_t` to access bpf:

1. Create a wiz-sensor.te file, with the following content:

    ```output
    module wiz-sensor 1.0;
    require {
        type unconfined_service_t;
        class bpf { map_create map_read map_write prog_load prog_run };
    }
    #============= unconfined_service_t ==============
    allow unconfined_service_t self:bpf { map_create map_read map_write prog_load prog_run };
    ```

2. Build the policy by running:

    `checkmodule -M -m -o wiz-sensor.mod wiz-sensor.te`

3. Create the SELinux policy module package by running:

    `semodule_package -o wiz-sensor.pp -m wiz-sensor.mod`

4. Insert the new policy by running:

    `semodule -i wiz-sensor.pp`

### How to restart the Linux Sensor

The Linux Sensor runs as systemd daemon.

To restart it, run the following command:

`sudo systemctl restart wiz-sensor`

## Contact support

If none of the scenarios above match your case, please contact us:

1. [Create a support package for the Runtime Sensor](#create-a-support-package-for-the-runtime-sensor)
2. Open the Support Case and include the support package.

### Create a support package for the Runtime Sensor

The following script executes various troubleshooting commands and saves the output to an archive named support_package_linux.tar.gz. Please attach this file when contacting Wiz support.

:warning: You should run the script as the root user because it will collect sensor related information from the /opt/wiz/sensor folder which requires root permissions

```
#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Set the sensor directory based on the OS
sensor_dir="/opt/wiz/sensor"
if grep -q "Container-Optimized OS from Google" /etc/os-release; then
    sensor_dir="/var/lib/wiz/sensor"
fi

# Create a directory to store the support package
support_dir="./support_package_$(date +'%Y%m%d%H%M%S')"
mkdir -p "$support_dir"

# Define the log file path inside the support package folder
log_file="$support_dir/support_package.log"
touch "$log_file"

# Function to log errors
log_error() {
    echo "[ERROR] $1" >> "$log_file"
}

# Function to run a command and log any errors
run_command() {
    command="$1"
    output="$2"
    eval "$command" >> "$output" 2>> "$log_file"
}

# Collect system information
run_command "uname -a" "$support_dir/system_info.txt"
run_command "df -h" "$support_dir/disk_space.txt"
run_command "free -h" "$support_dir/mem_usage.txt"
run_command "top -b -n 1" "$support_dir/cpu_usage.txt"
run_command "mount" "$support_dir/mount.txt"

# Get the system ulimits
run_command "ulimit -a" "$support_dir/ulimit.txt"
# Checks if SELinux is configured
run_command "ls -l /etc/selinux/config" "$support_dir/SELinux.txt"
# Prints the SELinux status
run_command "sestatus" "$support_dir/SELinux_status.txt"
# Get the current kernel config
run_command "cat /boot/config-$(uname -r)" "$support_dir/kernel_config.txt"

# Collect I/O usage using iostat (alternative to iotop)
run_command "iostat -d 1 2" "$support_dir/io_usage.txt"

run_command "df -Th $sensor_dir" "$support_dir/filesystem_type.txt"
run_command "ps aux" "$support_dir/process_list.txt"

# Collect Wiz related processes
run_command "ps awx | grep wiz" "$support_dir/wiz_processes.txt"

# Collect systemd information
run_command "systemctl --version" "$support_dir/systemd_version.txt"
run_command "systemctl show wiz-sensor" "$support_dir/systemd_config.txt"
run_command "journalctl -u wiz-sensor" "$support_dir/systemd_log.txt"

# Collect docker information
run_command "docker version" "$support_dir/docker_version.txt"

# Collect dmesg output
run_command "dmesg" "$support_dir/dmesg.txt"

# Retrieve BIOS version
run_command "cat /sys/class/dmi/id/bios_version" "$support_dir/bios_version.txt"

# List the contents of the sensor directory
run_command "ls -l $sensor_dir/" "$support_dir/sensor_dir.txt"

# See if IMDS is enabled
run_command "curl -s http://169.254.169.254/" "$support_dir/imds.txt"

# Run some sensor CLI commands

# First check if Sensor is running as a docker container or just natively
DOCKER_CONTAINER_COUNT=$(docker ps --format "{{.Names}}" -f name=wiz-sensor | wc -l)

# Check if the sensor is installed and running as a Docker container
if [ $DOCKER_CONTAINER_COUNT -ge 1 ]; then
    # If it's a container, run sensor CLI using docker exec
    echo "Sensor is running as a Docker container"
    run_command "docker logs wiz-sensor" "$support_dir/docker_logs.txt"
    run_command "docker exec wiz-sensor /usr/src/app/wiz-sensor version" "$support_dir/sensor_version.txt"
    run_command "docker exec wiz-sensor /usr/src/app/wiz-sensor get-statistics" "$support_dir/sensor_statistics.txt"
    run_command "docker exec wiz-sensor /usr/src/app/wiz-sensor actors" "$support_dir/sensor_actors.txt"
    run_command "docker exec wiz-sensor /usr/src/app/wiz-sensor containers" "$support_dir/sensor_containers.txt"
else
    # If not a container, run some sensor CLI commands
    echo "Sensor is running natively (not as a Docker)"
    run_command "$sensor_dir/sensor_init sensor_cli version" "$support_dir/sensor_version.txt"
    run_command "$sensor_dir/sensor_init sensor_cli get-statistics" "$support_dir/sensor_statistics.txt"
    run_command "$sensor_dir/sensor_init sensor_cli actors" "$support_dir/sensor_actors.txt"
    run_command "$sensor_dir/sensor_init sensor_cli containers" "$support_dir/sensor_containers.txt"
fi



# Copy the entire contents of the sensor directory to the support package
cp -r "$sensor_dir" "$support_dir"

# Archive the support package
tar -czvf "./support_package_linux.tar.gz" -C "$(dirname $support_dir)" "$(basename $support_dir)" > /dev/null 2>&1

# Remove the support directory
rm -r "$support_dir"

echo "Support package created at ./support_package_linux.tar.gz"

```
<!--Import from Wiz Doc Ends here -->

<!-- ## Links to further Documentation -->
