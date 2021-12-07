# Installation

1. Create a k8s cluster in standard mode in GKE `c1-us-west1-meet-cluster`, with at least two zones
   Recommended k8s node spec:
    - 20 CPU
    - 18GB memory
    - 50GB disk
    - Initial node: 1
    - Auto scale: 1 - 10
    - preemptible nodes

2. Switch to that k8s cluster

    ```bash
    ./switch_to_c1-us-west1-meet-cluster.sh
    ```

3. Create Cluster Admin for Metacontroller

    ```bash
    kubectl create clusterrolebinding zhangkan440-cluster-admin-binding --clusterrole=cluster-admin --user=zhangkan440@gmail.com
    ```

4. Deploy everything

    ```bash
    ./secrets.sh secretsfile

    cd overlays/gcp/us-west1/jisti
    kustomize build . | kubectl apply -f -

    cd ../ops
    kustomize build . | kubectl apply -f -

    git reset --hard
    ```

5. Reserve a static IP in GCP <https://console.cloud.google.com/networking/addresses/list> for the load balancer.

6. Go to <https://c1-us-west1.meet.livestand.io/grafana> and change the default admin password `admin:admin`
