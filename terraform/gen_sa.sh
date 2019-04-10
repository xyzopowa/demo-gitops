#!/bin/bash

PROJECT_ID=
_TFM_GC_SA=terraform
_TFM_GC_SAFULL="${_TFM_GC_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
CREDFILE="./credentials.json"

# enable KMS API
gcloud services enable \
  cloudapis.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  --project ${PROJECT_ID}
sleep 5
echo "list of enabled API"
gcloud services list --project ${PROJECT_ID} --enabled

gcloud iam service-accounts create ${_TFM_GC_SA} \
    --display-name "terraform service account" --project ${PROJECT_ID}

# list service account
gcloud iam service-accounts list --project ${PROJECT_ID}
gcloud iam service-accounts keys create \
  --iam-account "${_TFM_GC_SAFULL}" --project ${PROJECT_ID} ${CREDFILE}

# add role
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${_TFM_GC_SAFULL} --role roles/owner
