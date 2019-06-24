#!/usr/bin/env bash

set -eux

declare -r project='gitlab-ops'
declare -r bucket='gitlab-configs'
declare -r kms_keyring='gitlab-shared-configs'
declare -r kms_key='config'
declare -r chef_file='chef_alertmanager.yml'
declare -r k8s_file='k8s_alertmanager.yaml'

gcloud auth activate-service-account --key-file "${SERVICE_KEY}"
gcloud config set project "${project}"

gcloud --project "${project}" kms encrypt --location=global --keyring="${kms_keyring}" --key="${kms_key}" --ciphertext-file="${chef_file}".enc --plaintext-file="${chef_file}"
gcloud --project "${project}" kms encrypt --location=global --keyring="${kms_keyring}" --key="${kms_key}" --ciphertext-file="${k8s_file}".enc --plaintext-file="${k8s_file}"
gsutil cp alertmanager.yml.enc gs://"${bucket}"/"${chef_file}".enc
gsutil cp alertmanager.yml.enc gs://"${bucket}"/"${k8s_file}".enc
