GitOps - Canary CI/CD demo
------------------------

This is a step by step guide on how to set up a GitOps workflow with Istio/flagger and Weave Flux. GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure and workloads. In practice this means using git push instead of kubectl create/apply or helm install/upgrade.
 
Requirements
------------

  * GCP Project;
  * GitHub token;
  * helm, terraform, kubectl, gcloud, fluxctl and git binaries.
  * Fork this repo
  * CircleCi (Optionnal)

Spin up the environment
-----------------------

Fork the repo to your account and clone the repo on your PC, and then go to the terraform folder

```bash
git clone git@github.com:<your_account>/demo-gitops
cd demo-gitops/terraform
```

Export your Project ID and your github token to a variable, and then execute the script.

```bash
# script that creates a service account to deploy the cluster via terraform.

export GOOGLE_PROJECT=<your_projectid>
export GITHUB_TOKEN=<your_github_token>
export GIT_REPO=demo-gitops
export GITHUB_ORGANIZATION=<your_account_name>

bash gen_sa.sh
```

Start creating the cluster with terraform

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Terraform will deploy:

* A VPC and a subnet
* A Public GKE cluster
* Tiller for Helm
* Weave Flux
* Add the public key to the repo

You now have the necessary environment to experiment with the concepts of gitops and canary deployments.

Let's start to use Gitops
-------------------------

Now we will be able to deploy different applications via gitop on our cluster. Let's start by deploying the necessary infrastructure applications.

Go to the flux/istio folder and change the flux.weave.works/ignore annotation:'true' to false on all yaml files

```bash
# Change the ignore annotation to false to deploy istio
cd flux/istio
sed -i "s/true/false/" *.yaml
git add *.yaml && git commit -m "change ignore annotation to false [ci skip]" && git push

# Forces the repo synchronization
fluxctl sync --k8s-fwd-ns flux

# Show flux logs
kubectl -n flux logs -f $(kubectl -n flux get pods -l app=flux -o jsonpath='{.items[0].metadata.name}')
```

Flux reads the repo when the "fluxctl sync" command is launched, and applies the configuration present in the flux folder. The annotation flux.weave.works/ignore: true prevented the deployment. 

Now check that everything is installed, before continuing this tutorial

```bash
kubectl get pods -n istio-system
NAME                                      READY   STATUS      RESTARTS   AGE
flagger-85dd9b4967-2np58                  1/1     Running     0          10d
grafana-7b46bf6b7c-pvf8x                  1/1     Running     0          10d
istio-citadel-5bf5488468-m9phx            1/1     Running     0          10d
istio-egressgateway-7f9c5f6bb5-dlxpw      1/1     Running     0          10d
...
```

Canary deployment with Istio/Flagger
------------------------------------

Flagger takes a Kubernetes deployment and optionally a horizontal pod autoscaler (HPA) and creates a series of objects (Kubernetes deployments, ClusterIP services and Istio virtual services) to drive the canary analysis and promotion.

### Canary Custom Resource

For a deployment named _myapp_, a canary promotion can be defined using Flagger's custom resource:

```yaml
apiVersion: flagger.app/v1alpha3
kind: Canary
metadata:
  name: myapp
  namespace: test
spec:
  # deployment reference
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  # the maximum time in seconds for the canary deployment
  # to make progress before it is rollback (default 600s)
  progressDeadlineSeconds: 60
  # HPA reference (optional)
  autoscalerRef:
    apiVersion: autoscaling/v2beta1
    kind: HorizontalPodAutoscaler
    name: myapp
  service:
    # container port
    port: 9898
    # service port name (optional, will default to "http")
    portName: http-myapp
    # Istio gateways (optional)
    gateways:
    - cloud-gw.istio-system.svc.cluster.local
    - mesh
    # Istio virtual service host names (optional)
    hosts:
    - myapp.example.com
  # promote the canary without analysing it (default false)
  skipAnalysis: false
  # define the canary analysis timing and KPIs
  canaryAnalysis:
    # schedule interval (default 60s)
    interval: 1m
    # max number of failed metric checks before rollback
    threshold: 10
    # max traffic percentage routed to canary
    # percentage (0-100)
    maxWeight: 50
    # canary increment step
    # percentage (0-100)
    stepWeight: 5
    # Istio Prometheus checks
    metrics:
    - name: istio_requests_total
      # minimum req success rate (non 5xx responses)
      # percentage (0-100)
      threshold: 99
      interval: 1m
    - name: istio_request_duration_seconds_bucket
      # maximum req duration P99
      # milliseconds
      threshold: 500
      interval: 30s
    # external checks (optional)
    webhooks:
      - name: integration-tests
        url: http://myapp.test:9898/echo
        timeout: 1m
        # key-value pairs (optional)
        metadata:
          test: "all"
          token: "16688eb5e9f289f1991c"
```

### Istio Gateways and Virtual services

#### Gateways

A Gateway configures a load balancer for HTTP/TCP traffic operating at the edge of the mesh, most commonly to enable ingress traffic for an application.

Unlike Kubernetes Ingress, Istio Gateway only configures the L4-L6 functions (for example, ports to expose, TLS configuration). Users can then use standard Istio rules to control HTTP requests as well as TCP traffic entering a Gateway by binding a VirtualService to it.

#### Virtual services

A VirtualService defines the rules that control how requests for a service are routed within an Istio service mesh. For example, a virtual service could route requests to different versions of a service or to a completely different service than was requested. Requests can be routed based on the request source and destination, HTTP paths and header fields, and weights associated with individual service versions.

### Check the configuration

The istio gateway was deployed by flux via the istio-gw.yaml file of the repo. The Virtual service part will be automatically created by Flagger. We will now have to deploy our application and create the Canary file to Flagger

```bash
# Check the Istio GW configuration
kubectl get gateway -n istio-system  -o yaml

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: cloud-gw
  namespace: istio-system
  annotations:
    flux.weave.works/ignore: 'false'
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

Application Deployment with Helm
--------------------------------

### CircleCI pipeline

 We need a CI pipeline to build and push our application to a public registry. We'll use circleCI for the demo. you just need to connect your repo to a project in CircleCI and set the following variables.

* DOCKER_PASS: Password of your account (Docker Hub only)
* DOCKER_USER: Login of your account (Docker Hub only)

### Application code

The demo application is just a web server in Golang displaying a html page. The code is in the app folder of the repo.

Now your CI pipeline should work, try to modify the index.html file or change the image in the docker/static folder to change the website design.

```bash
# Change the welcome message
vi docker/static/index.html
git add index.html && git commit -m "update website" && git push
```
Each modification in the repo will launch a new pipeline, and a new image will be build with a new tag (incremented with the build number)

### Application deployment

For the example we will deploy an application managed with Helm. The chart is directly in the repo. It contains the configuration of the application as well as Flagger's configuration for the Canary deployment.

Let's look at the different values that can be configured, in the flux/istio/myapp.yaml file.

```yaml
apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: myapp
  namespace: myapp
  annotations:
    flux.weave.works/ignore: 'true'
    flux.weave.works/automated: "true" # Check periodically in the registry for a new image
    flux.weave.works/tag.chart-image: "glob:1.0.*-master" # filter to update the image
spec:
  releaseName: myapp 
  chart:
    git: git@github.com:skhedim/demo-gitops.git
    path: charts/myapp
    ref: master
  values:
    image:
      repository: REPO/demo-gitops # The image to use for the app
      tag: 1
      canary:
        enabled: true
        istioIngress:
          enabled: true
          gateway: cloud-gw.istio-system.svc.cluster.local # Istio Gateway
          host: myapp.example.org # the DNS name of the app
        loadtest:
          enabled: true
```

Change the repo with your account and commit the changes.

```bash
# Change the docker hub repo with yours

cd flux/myapp
sed -i "s/true/false/" *.yaml
sed -i "s/REPO/<your_dockerhub_account>" myapp.yaml
git add *.yaml && git commit -m "change ignore annotation to false [ci skip]" && git push
fluxctl sync --k8s-fwd-ns flux

# Check if you can see the canary configuration

```bash
kubectl get canary -n myapp
NAME    STATUS        WEIGHT   LASTTRANSITIONTIME
myapp   Initialized   0        2019-04-01T08:33:42Z

# Check if you can see the index page

kubectl -n myapp port-forward $(kubectl -n myapp get pods -l app=myapp-primary -o jsonpath='{.items[0].metadata.name}') 80:8080

# You should see your welcome message with the URL: http://localhost:8080
```

Canary deployment
-----------------

Now everything is in place to test a canary deployment. Flagger monitors the myapp deployment,and waits for the image to be changed to create a second deployment and a virtual service.

In parallel Flux monitors the registry and waits for a new tag to be pushed into the registry to update the deployment.

Finally circleCI is waiting for a new commit to build a new image and increment the tag with the build number.

Modify the index.html file again to trigger a new build

```bash
# Change the welcome message

vi docker/static/index.html
git add index.html && git commit -m "update website" && git push

# Wait for flux to detect the new image in the registry

kubectl -n flux logs -f $(kubectl -n flux get pods -l app=flux -o jsonpath='{.items[0].metadata.name}')
```

