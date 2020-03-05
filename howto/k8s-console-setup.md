## Summary

Access to the production and staging Kubernetes clusters are restricted to only
allow API connections from specific hosts.

This covers how to setup a linux host for
running the `k-ctl` where dependencies are installed in your home directory.

⚠️  ⚠️

Please do not run `k-ctl` outside of CI unless it is necessary for testing or
new deployments.

⚠️  ⚠️

## Requirements

* kubectl
* kubectx
* helm with tiller
* bash > 4.4

## Setup `.bash_profile`

This ensures that `$HOME/bin` is in your path and sets `$HELM_HOME`

```
export PATH="$HOME/bin:$PATH"
export HELM_HOME="$HOME/helm"
```

## Install k-ctl dependencies

### helm

Helm might already be installed on the host, if not you can install locally in
your homedir, for instructions reference https://helm.sh/docs/intro/install/

### kubectl

Kubectl might already be installed on the host, if not you can install locally in
your homedir, for instructions reference https://kubernetes.io/docs/tasks/tools/install-kubectl/

### kubectx

```
cd $HOME/workspace
git clone https://github.com/ahmetb/kubectx
ln -s $HOME/workspace/kubectx/kubectx $HOME/bin/kubectx
```

### bash > 4.4

k-ctl will use the bash in your environment so you just need to install it to
`$HOME/bin` for it it be picked up.

```
cd $HOME/workspace
wget https://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz
tar zxvf bash-4.4.tar.gz
cd bash-4.4/
./configure --prefix=$HOME
make
make install
```
