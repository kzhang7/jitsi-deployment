# Jitsi Meet

Scalable video conferencing on Kubernetes.

## Structure

The whole setup is based on Kubernetes YAML files and patches for these files.
It makes use of [kustomize](https://github.com/kubernetes-sigs/kustomize) to customize the raw YAMLs for each environment.

(Almost) every directory in the directory tree (depicted below) contains a `kustomize.yaml` file which defines resources (and possibly patches).

```
|-- base
|   |-- jitsi
|   |-- jitsi-shard
|   |   `-- jvb
|   `-- ops
|       |-- cert-manager
|       |-- dashboard
|       |-- ingress-nginx
|       |-- loadbalancer
|       |-- logging
|       |-- metacontroller
|       |-- monitoring
|       `-- reflector
`-- overlays
    |-- development
    |   |-- jitsi-base
    |   |-- ops
    |   |-- shard-0
    |   `-- shard-1
    `-- production
        |-- jitsi-base
        |-- ops
        |-- shard-0
        `-- shard-1
```

## Requirements

- [kubectl/v1.17.2+](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [kustomize/v3.5.4](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv3.5.4)
  _WARNING_: newer versions of kustomize currently don't work due to changes regarding remote sources

## Install

To install the full setup go to either [`overlays/development`](overlays/development) or
[`overlays/production`](overlays/production) and run

```bash
$ kustomize build . | kubectl apply -f -
```
This deploys a Jitsi setup consisting of two shards. A shard is a complete replica of a Jitsi setup that is used in
parallel to other shards to load-balance and for high availability. More shards can be added following the documentation
in [`docs/architecture/architecture.md`](docs/architecture/architecture.md). The setup was tested against a managed
Kubernetes cluster (v1.17.2) running on [IONOS Cloud](https://dcd.ionos.com/).

## Architecture

The Jitsi Kubernetes namespace has the following architecture:

![Architecture Jitsi Meet](docs/architecture/build/jitsi_meet_one_shard.png)

The setup shown above contains only a single shard (for visual clarity). Subsequent shards would be attached to the web
service. A more detailed explanation of the system architecture with multiple shards can be found in [docs/architecture/architecture.md](docs/architecture/architecture.md).

## Load Testing

Load testing is based on [jitsi-meet-torture](https://github.com/jitsi/jitsi-meet-torture) which is a Java application
that connects to a Jitsi instance as a user and shows a predefined video along with an audio stream by using a Selenium
Chrome instance. To run multiple test users in multiple conferences a Selenium hub set up with docker-compose is used.

Terraform scripts that set up the test servers with an existing image can be found under [`loadtest`](loadtest).
An [init script](loadtest/init.sh) is used to provision the necessary tools to that image. This image also needs SSH
access set up with public key authentication.

After starting a number of load test servers, the load test can be started by using the [`loadtest/run_loadtest.sh`](loadtest/run_loadtest.sh)
script (locally). Results can be found in [`docs/loadtests/loadtestresults.md`](docs/loadtests/loadtestresults.md).

## Kubernetes Dashboard Access

To access the installed [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) execute
```bash
$ kubectl proxy
```
and then go to `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`.

The login token can be received by executing
```bash
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

## Kibana Access

Kibana is not accessible from the Internet and must be forwarded to your local machine via `kubectl` by executing
```bash
$ kubectl port-forward -n logging svc/kibana-kb-http 5601:5601
```
After that you will be able to access Kibana via [https://localhost:5601/](https://localhost:5601/).
The default login password (user `elastic`) can be received with
```bash
$ kubectl get secret -n logging elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

The same procedure can be used to access Prometheus or Alertmanager.

## Relationship With Other Projects

The monitoring stack that is set up by this project is currently also used by an [affiliated project](https://github.com/schul-cloud/bbb-deployment)
for [Big Blue Button](https://bigbluebutton.org/). Therefore, some of the files here contain configurations to monitor
that setup. To exclude them delete all files starting with `bbb-` and remove the file names from the respective
`kustomization.yaml` files.

## Updates for GCP

1. Replace all storage class from `ionos-enterprise-hdd` to `standard` or `standard-rwo` or `premium-rwo` depends on your needs.

2. Update jisti to the latest version by replacing `stable-4548-1` with `stable-6433`.

   1. Update the `config.js` and `interface_config.js` to the latest version in `web-configmap.yaml`
   2. Update the `jitsi-meet.cfg.lua` to the latest version in `prosody-configmap.yaml`. See (<https://github.com/jitsi/docker-jitsi-meet/blob/master/prosody/rootfs/defaults/conf.d/jitsi-meet.cfg.lua>)

3. Add `XMPP_MUC_DOMAIN` env with value `muc.meet.jitsi` in `jicofo-deployment.yaml` to fix the [Communication with remote domains is not enabled] issue: <https://github.com/jitsi/docker-jitsi-meet/issues/929>

4. Add `PUBLIC_URL` env with value of the public URL in `prosody-deployment.yaml` and `web-deployment.yaml` to fix the wss pointing to localhost issue: <https://community.jitsi.org/t/solved-bridgechannel-js-85-websocket-connection-to-wss-localhost-8443-colibri-ws-failed/86752/4>

5. Added missing environment variables in `prosody-deployment.yaml` and `web-deployment.yaml`.

6. Change the default language by replacing `'de'` with `'en'` in web-configmap.yaml. Replace `Europe/Berlin` timezone with `UTC`.

7. Replace ZONE_1 and ZONE_2 with the appropriate zone names for `topology.kubernetes.io/zone` in all files.

    For example, Replace `topology.kubernetes.io/zone: ZONE_1` with `topology.kubernetes.io/zone: us-west1-a`

## Customization: Remove web deployments and move it to GCP app engine to save cost

1. Remove the following files:

   ```text
   web-configmap.yaml
   web-service.yaml
   web-deployment.yaml
   web-deployment-patch.yaml
   ```

2. Updated `haproxy-configmap.yaml` to point prosody svc directly

## Installation

1. Create a k8s cluster in standard mode in GKE (auto-pilot mode does not work), for example: `c1-us-west1.meet`, with at least two zones

2. Switch to that k8s cluster

    ```bash
    gcloud config set account zhangkan440@gmail.com
    gcloud config set project livestand
    gcloud container clusters get-credentials c1-us-west1.meet --region=us-west1
    kubectl config use-context gke_livestand_us-west1_c1-us-west1.meet
    ```

3. Install kustomize v3.5.4

    ```bash
    sudo cp kustomize /usr/bin
    sudo chmod 755 /usr/bin/kustomize
    ```

4. Update all the secrets

    ```bash
    vi secretsfile
    ./secrets.sh secretsfile production
    ```

5. Update the ingress domain

    Replace `jitsi.messenger.schule` with `c1-us-west1.meet.livestand.io`
    Replace `jitsi-messenger-schule` with `c1-us-west1-meet-livestand-io`

    Replace `jitsi.dev.messenger.schule` with `c1-us-west1.meet-dev.livestand.io`
    Replace `jitsi.staging.messenger.schule` with `c1-us-west1.meet-dev.livestand.io`

6. Install Metacontroller

    ```bash
    kubectl create clusterrolebinding zhangkan440-cluster-admin-binding --clusterrole=cluster-admin --user=zhangkan440@gmail.com
    kubectl apply -k https://github.com/metacontroller/metacontroller/manifests/production
    ```

7. Deploy everything

    ```bash
    cd overlays/production-monitoring
    kustomize build . | kubectl apply -f -

    cd overlays/production
    kustomize build . | kubectl apply -f -

    ```

8. Reserve a static IP in GCP <https://console.cloud.google.com/networking/addresses/list> for the load balancer.
