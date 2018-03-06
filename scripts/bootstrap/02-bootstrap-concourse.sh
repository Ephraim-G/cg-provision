#!/bin/bash

set -eux

# Collect AWS variables
bosh interpolate \
  ./bosh/varsfiles/collect-aws-variables.yml \
  -l ${WORKSPACE_DIR}/terraform-outputs.json \
  -l ${WORKSPACE_DIR}/aws-keypair.json \
  > ${WORKSPACE_DIR}/aws-variables.yml

# Deploy bootstrap concourse
bosh create-env ../concourse-deployment/lite/concourse.yml \
  --state ${WORKSPACE_DIR}/bootstrap-concourse-state.json \
  --vars-store ${WORKSPACE_DIR}/bootstrap-concourse-creds.yml \
  -o ../concourse-deployment/lite/infrastructures/aws.yml \
  -o ./bosh/opsfiles/basic-auth.yml \
  -o ./bosh/opsfiles/self-signed-tls.yml \
  -o ./bosh/opsfiles/iam-instance-profile.yml \
  -l ../concourse-deployment/versions.yml \
  -o ./bosh/opsfiles/ssh-tunnel.yml \
  -o ./bosh/opsfiles/vip-network.yml \
  -l ${WORKSPACE_DIR}/aws-variables.yml \
  -v region=${AWS_DEFAULT_REGION} \
  -v default_key_name=bootstrap \
  -v az=${TF_VAR_az1} \
  -v access_key_id=${AWS_ACCESS_KEY_ID} \
  -v secret_access_key=${AWS_SECRET_ACCESS_KEY}

echo "Deployed bootstrap concourse. Login at:

https://$(cat ${WORKSPACE_DIR}/terraform-outputs.json | jq -r '.public_ip.value'):4443

Username: bootstrap
Password: $(bosh interpolate ${WORKSPACE_DIR}/bootstrap-concourse-creds.yml --path /basic-auth-password)"
