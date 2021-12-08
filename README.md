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

## Updates to make

1. Replaced all storage class from `ionos-enterprise-hdd` to `standard`.

2. Updated jisti to the latest version by replacing `stable-4548-1` with `stable-6433`.

   1. Updated the `config.js` and `interface_config.js` to the latest version in `web-configmap.yaml`
   2. Updated the `jitsi-meet.cfg.lua` to the latest version in `prosody-configmap.yaml`. See (<https://github.com/jitsi/docker-jitsi-meet/blob/master/prosody/rootfs/defaults/conf.d/jitsi-meet.cfg.lua>)

3. Added `XMPP_MUC_DOMAIN` env with value `muc.meet.livestand.io` in `jicofo-deployment.yaml` to fix the [Communication with remote domains is not enabled] issue: <https://github.com/jitsi/docker-jitsi-meet/issues/929>

4. Added `PUBLIC_URL` env with value of the public URL in `prosody-deployment.yaml` and `web-deployment.yaml` to fix the wss pointing to localhost issue: <https://community.jitsi.org/t/solved-bridgechannel-js-85-websocket-connection-to-wss-localhost-8443-colibri-ws-failed/86752/4>

5. Added missing environment variables in `prosody-deployment.yaml` and `web-deployment.yaml`.

6. Changed the default language by replacing `'de'` with `'en'` in `web-configmap.yaml`. Replace `Europe/Berlin` timezone with `UTC`.

7. Removed all `bbb-` and `turn-` related configurations

8. Install kustomize v3.5.4

    ```bash
    sudo cp kustomize /usr/bin
    sudo chmod 755 /usr/bin/kustomize
    ```

## Customizations for livestand

1. Removed the web stack and used GCP app engine to make the frontend customization easier.
   Removed the following file:

   ```text
   web-configmap.yaml
   web-service.yaml
   web-deployment.yaml
   web-deployment-patch.yaml
   ```

   Updated `haproxy-configmap.yaml` to point prosody svc directly

2. Replaced `jitsi-messenger-schule` with `meet-livestand-io` in all files
   Replaced `jitsi.dev.messenger.schule` with `meet-dev.livestand.io` in all files
   Replaced `jitsi.staging.messenger.schule` with `meet-dev.livestand.io` in all files

## Installation

To install the full setup for each cloud, please read [`overlays/{gcp|aws|azure|ionos}/{region}/README.md`](overlays/{gcp|aws|azure|ionos}/{region}/README.md)

## Troubleshoot

## Sample meetings

User 1: <https://meet.livestand.io/IOSAppHomePageDisscussion-kj9uesqg_us1?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJqaXRzaSIsInN1YiI6Im1lZXQtdXMtd2VzdDEubGl2ZXN0YW5kLmlvIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiJsaXZlc3RhbmQuaW8iLCJyb29tIjoiSU9TQXBwSG9tZVBhZ2VEaXNzY3Vzc2lvbi1rajl1ZXNxZ191czEiLCJjb250ZXh0Ijp7InVzZXIiOnsibmFtZSI6IkpXVCBVc2VyMSJ9fX0.zVWbjdJY2EpUUETqqmytsvehTJfHztKvtprh_CS6CSY>

User 2: <https://meet.livestand.io/IOSAppHomePageDisscussion-kj9uesqg_us1?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsaXZlc3RhbmQuaW8iLCJzdWIiOiJsaXZlc3RhbmQuaW8iLCJpYXQiOjE1MTYyMzkwMjMsImlzcyI6ImxpdmVzdGFuZC5pbyIsInJvb20iOiJJT1NBcHBIb21lUGFnZURpc3NjdXNzaW9uLWtqOXVlc3FnX3VzMSIsImNvbnRleHQiOnsidXNlciI6eyJuYW1lIjoiSldUIFVzZXIyIn19fQ.enFBdq91VogYIIy7MyM3hb7xPLfQVd8t_RMrvzUHo7U>

### Meetings are not routed to the correct shard

   1. Login to haproxy and install the tools

      ```bash
      kubectl exec -it haproxy-{0|1|2|...} -n jitsi -- /bin/bash
      apt-get install watch socat -y
      ```

   2. View the stick-table data and make sure all the haproxy nodes has the same data

      ```bash
      watch -n 1 'echo "show table jitsi-meet" | socat unix:/var/run/hapee-lb.sock -'
      ```

   3. View the stats and make sure the backend are healthy with the same ip across the haproxy nodes

      ```bash
      echo "show stat" | socat unix:/var/run/hapee-lb.sock -
      ```

### Kill the stuck namespace

```bash
(
NAMESPACE=jitsi
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
)
```
