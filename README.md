# OpenShift with Windows Workers
Automated installation of Windows workers on OpenShift 4.11+.  These are all pulled from the [official docs](https://docs.openshift.com/container-platform/4.11/windows_containers/enabling-windows-container-workloads.html).

## Prereq

1.  OpenShift 4.11 or later

2.  Must have user with `cluster-admin` access and is currently logged into the cluster via command line

3.  Installed with IPI or UPI with `platform:none` configured at install time

4.  Cluster must be OVN Kubernetes Hybrid networking
You can configure your cluster to use hybrid networking with OVN-Kubernetes. This allows a hybrid cluster that supports different node networking configurations. For example, this is necessary to run both Linux and Windows nodes in a cluster.
You must configure hybrid networking with OVN-Kubernetes during the installation of your cluster. You cannot switch to hybrid networking after the installation process.

If you must set this up, install a new cluster and follow these [instructions](https://docs.openshift.com/container-platform/4.11/networking/ovn_kubernetes_network_provider/configuring-hybrid-networking.html) or for more concise [instructions](https://github.com/openshift/windows-machine-config-operator/blob/master/docs/setup-hybrid-OVNKubernetes-cluster.md).

Windows Server Long-Term Servicing Channel (LTSC): Windows Server 2019 is not supported on clusters with a custom hybridOverlayVXLANPort value because this Windows server version does not support selecting a custom VXLAN port.

```shell
oc describe network.config/cluster | yq e '.Spec.["Network Type"]'
# OVNKubernetes
```

## Installation

### Automated

Run `./install.sh`

### Manual

1. Install `Windows Machine Config Operator` from Red Hat (not Community, unless you want to) using the OperatorHub in the OpenShift Web Console

2. Generate secret - make it different than the ssh key used during cluster installation

```shell
ssh-keygen -t ed25519 -N '' -f ./windows-key
oc create secret generic cloud-private-key --from-file=private-key.pem=./windows-key -n openshift-windows-machine-config-operator
```

3. Find AMI

```shell
Supported Versions of Windows:
Amazon Web Services (AWS) - Windows Server 2019, version 1809
Microsoft Azure - Windows Server 2022, OS Build 20348.681 or later AND Windows Server 2019, version 1809
```

AWS for example, find the right AMI:

```shell
aws ec2 describe-images --region <aws region name> --filters "Name=name,Values=Windows_Server-2019*English*Full*Containers*" "Name=is-public,Values=true" --query "reverse(sort_by(Images, &CreationDate))[*].{name: Name, id: ImageId}" --output table
```

gives you something like:

```shell
-------------------------------------------------------------------------------------------
|                                     DescribeImages                                      |
+------------------------+----------------------------------------------------------------+
|           id           |                             name                               |
+------------------------+----------------------------------------------------------------+
|  ami-0ec317eee5f7e45f0 |  Windows_Server-2019-English-Full-ContainersLatest-2022.12.28  |
|  ami-0e2306ebbb87565e5 |  Windows_Server-2019-English-Full-ContainersLatest-2022.12.14  |
|  ami-0e13a4628d2471645 |  Windows_Server-2019-English-Full-ContainersLatest-2022.11.10  |
|  ami-0181ef1b805f2034a |  Windows_Server-2019-English-Full-ContainersLatest-2022.10.27  |
|  ami-07452ff7be76f04cf |  Windows_Server-2019-English-Full-ContainersLatest-2022.10.12  |
|  ami-03ea26e077348a15c |  Windows_Server-2019-English-Full-ContainersLatest-2022.09.14  |
+------------------------+----------------------------------------------------------------+
```

So using latest: `ami-0ec317eee5f7e45f0`

4. Create machine set

```shell
# change availabilty zone and region as needed
oc project openshift-machine-api
oc process -f ./machine-set-template.yaml -p INFRA_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster) -p ZONE=us-east-1a -p REGION=us-east-1 -p AMI=ami-0ec317eee5f7e45f0 | oc create -f -
```

5. Create runtime class

```shell
oc create -f ./runtime-class.yaml`
```

## Sample App
Run `oc create -f ./app.yaml`

## Uninstallation
This will remove the app as well as the machine sets, runtime class, and operator completely.

### Automated
Run `./destroy.sh`

### Manual
1. Delete app

```shell
oc delete -f ./app.yaml
```

2. Delete operator

```shell
oc delete -f ./operator.yaml
```

3. Delete machine set

```shell
# change availabilty zone and region as needed
oc project openshift-machine-api
oc process -f ./machine-set-template.yaml -p INFRA_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster) -p ZONE=us-east-1a -p REGION=us-east-1 -p AMI=ami-0ec317eee5f7e45f0 | oc delete -f -
```

4. Delete ruleset class

```shell
oc delete -f ./runtime-class.yaml
```
