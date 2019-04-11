#!/bin/bash

_TFM_GC_SA=terraform
_TFM_GC_SAFULL="${_TFM_GC_SA}@${GOOGLE_PROJECT}.iam.gserviceaccount.com"
CREDFILE="./credentials.json"

# Add repo name to TF variables
sed -i "s&your_repo&$GIT_REPO&" terraform.tfvars

# enable KMS API
gcloud services enable \
  cloudapis.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  --project ${GOOGLE_PROJECT}
sleep 5
echo "list of enabled API"
gcloud services list --project ${GOOGLE_PROJECT} --enabled

gcloud iam service-accounts create ${_TFM_GC_SA} \
    --display-name "terraform service account" --project ${GOOGLE_PROJECT}

# list service account
gcloud iam service-accounts list --project ${GOOGLE_PROJECT}
gcloud iam service-accounts keys create \
  --iam-account "${_TFM_GC_SAFULL}" --project ${GOOGLE_PROJECT} ${CREDFILE}

# add role
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} \
  --member serviceAccount:${_TFM_GC_SAFULL} --role roles/owner
