GitOps - Canary CI/CD demo
------------------------

This is a step by step guide on how to set up a GitOps workflow with Istio/flagger and Weave Flux. GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure and workloads. In practice this means using git push instead of kubectl create/apply or helm install/upgrade.
 
Requirements
------------

  * GCP Project;
  * GitHub token;
  * helm, terraform, kubectl, gcloud and git binaries.
  * Fork this repo
  * CircleCi (Optionnal)

Spin up the environment
-----------------------

Clone the repo on your PC, and then go to the terraform folder

```bash
git clone git@github.com/skhedim/demo-gitops
cd demo-gitops/terraform
```

Export your Project ID and your github token to a variable, and then execute the script.

```bash
# script that creates a service account to deploy the cluster via terraform.

export GOOGLE_PROJECT=<your_projectid>
export GITHUB_TOKEN=<your_github_token>
export GIT_REPO=<your_git_repo>

bash gen_sa.sh
```

Start creating the cluster with terraform

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

