# `gitlab_users` cookbook segmentation fault when creating new user on OS Login instances

**Table of contents**

[[_TOC_]]

## The problem

There is a known problem of `chef-client` run failing with segmentation fault
when creating a new system user account when OS Login is enabled on the GCP VM.

The easiest way to fix it would be to disable OS Login. However...

We use OS Login on our Runner Managers to handle authentication from the CI/CD
pipeliens that execute the deployments. Most times it doesn't create any problems.

But whenever a new user will be added in chef-repo's databags and will be assigned
to either `production` or `ci` group, `gitlab_users::default` recipe will try to
create it. Chef's user provider tries to search if such user exists and for some reason
- only when it's done in context of chef! - that call fails with an error like this one:

```
Recipe: gitlab_users::default
  * execute[felipe] action run (skipped due to only_if)
  * linux_user[felipe] action remove (skipped due to only_if)
  * execute[idrozdov] action run (skipped due to only_if)
  * linux_user[idrozdov] action remove (skipped due to only_if)
  (...)
  * execute[ankelly] action run (skipped due to only_if)
  * linux_user[ankelly] action remove (skipped due to only_if)
  * execute[mfrankiewicz] action run (skipped due to only_if)
  * linux_user[mfrankiewicz] action remove (skipped due to only_if)
  * linux_user[fshabir] action create/opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/provider/user.rb:49: [BUG] Segmentation fault at 0x0000000000000000
ruby 2.5.5p157 (2019-03-15 revision 67260) [x86_64-linux]

-- Control frame information -----------------------------------------------
c:0030 p:---- s:0154 e:000153 CFUNC  :getpwnam
c:0029 p:0056 s:0149 e:000148 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/provider/user.rb:49
c:0028 p:0058 s:0143 e:000142 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/provider.rb:165
c:0027 p:0203 s:0138 e:000137 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource.rb:578
c:0026 p:0069 s:0128 e:000127 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/runner.rb:70
c:0025 p:0009 s:0119 e:000118 BLOCK  /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/runner.rb:98 [FINISH]
c:0024 p:---- s:0115 e:000114 CFUNC  :each
c:0023 p:0014 s:0111 e:000110 BLOCK  /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/runner.rb:98
c:0022 p:0010 s:0107 e:000106 BLOCK  /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource_collection/resource_list.rb:94 [FINISH]
c:0021 p:0085 s:0102 e:000101 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource_collection/stepable_iterator.rb:114
c:0020 p:0018 s:0098 e:000097 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource_collection/stepable_iterator.rb:85
c:0019 p:0010 s:0094 e:000093 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource_collection/stepable_iterator.rb:103
c:0018 p:0017 s:0090 e:000089 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource_collection/stepable_iterator.rb:55
c:0017 p:0025 s:0085 E:0003d0 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/resource_collection/resource_list.rb:92
c:0016 p:0023 s:0081 E:001778 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/runner.rb:97
c:0015 p:0059 s:0076 e:000075 BLOCK  /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/client.rb:720 [FINISH]
c:0014 p:---- s:0072 e:000071 CFUNC  :catch
c:0013 p:0010 s:0067 e:000066 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/client.rb:715
c:0012 p:0006 s:0061 e:000060 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/client.rb:754
c:0011 p:0391 s:0054 e:000053 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/client.rb:286
c:0010 p:0014 s:0042 E:000350 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/application.rb:303
c:0009 p:0091 s:0038 e:000037 BLOCK  /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/application.rb:279
c:0008 p:0007 s:0034 e:000033 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/local_mode.rb:44
c:0007 p:0040 s:0030 e:000029 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/application.rb:261
c:0006 p:0099 s:0025 e:000024 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/application/client.rb:449
c:0005 p:0019 s:0020 e:000019 METHOD /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/lib/chef/application.rb:66
c:0004 p:0063 s:0016 e:000015 TOP    /opt/chef/embedded/lib/ruby/gems/2.5.0/gems/chef-14.13.11/bin/chef-client:25 [FINISH]
c:0003 p:---- s:0013 e:000012 CFUNC  :load
c:0002 p:0630 s:0008 E:000be0 EVAL   /opt/chef/bin/chef-client:81 [FINISH]
c:0001 p:0000 s:0003 E:000ea0 (none) [FINISH]
```

After spending few days on debugging that, we couldn't find what exactly causes the
segmentation fault on the `Etc.getpwnam('username')` call. It most probably have something
to do with the `nsswitch` configuration set to query `passwd` entries also through OS Login
and OS Login Cache.

To not waste more time, we've defined a workaround for this problem.

## The workaround

When `chef-client` runs will start reporting problems (which we have alerts for but we also
will see the segmentation fault showed above in the logs of deployment CI/CD jobs), the workaround
is to execute a `chef-client` run with the run list limited only to the `gitlab_users::default`
recipe and with the OS Login deactivated for that moment.

### Step 1: prepare scripting

Login to the Runner Manager that you need to fix and switch to `root`:

```bash
sudo -i
```

Being `root`, copy the following script and execute in the shell:

```bash
bin=/root/oslogin_fix.sh
attr=/root/oslogin_fix.attr

touch "${bin}"
chmod +x "${bin}"
touch "${attr}"

cat > "${attr}" <<EOF
{
  "gitlab_users": {
    "groups": [
      "production",
      "ci"
    ]
  }
}
EOF

cat > "${bin}" <<EOF
#!/usr/bin/env bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'
set -euo pipefail

__msg() {
    echo -e "\033[32;1m\${@}\033[30;0m"
}

__osl_status() {
    if google_oslogin_control status; then
        __msg "os-login is activated"
        return 0
    else
        __msg "os-login is deactivated"
        return 1
    fi
}

__osl_activate() {
    __msg "Activating os-login"
    google_oslogin_control activate
    __osl_status || true
}

__osl_deactivate() {
    __msg "Deactivating os-login"
    google_oslogin_control deactivate
    __osl_status || true
}

__chef_run() {
    __msg "Executing limited chef-client run"
    /opt/chef/bin/chef-client -o 'recipe[gitlab_users::default]' -j "${attr}"
}

__osl_status
__osl_deactivate
__chef_run
__osl_activate

__msg "All should be fixed now!"

EOF
```

This will prepare a `/root/oslogin_fix.sh` script and the `/root/oslogin_fix.attr` file
with the attributes for the recipe.

### Step 2: run the fix script

Having that ready you can now execute the fix script. Still being `root` execute this
in the shell:

```bash
/root/oslogin_fix.sh
```

This will temporarily deactivate OS Login, run `chef-client` limited to just the
`gitlab_users::default` recipe and ensure that all the needed user accounts in the
`production` and `ci` groups are created. After that it will re-activate the
OS Login.

### Step 3: solved

At this moment the problem should be solved until the next time when a new user
will be added to the list.

Alerts triggered by chef run errors should disappear. And if you're trying to handle
the deployment, you should be again fine to execute the `/runner run ...` chatops
commands to handle deployments.

