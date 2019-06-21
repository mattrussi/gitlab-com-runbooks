#!/usr/bin/env bash

set -eux

# TODO this should live in ops probably
# TODO need to get authentication setup somewhere
# TODO validate gcloud tooling in the CI image
gcloud --project gitlab-pre kms encrypt --location=global --keyring=skarbek-test --key=skarbek-test --ciphertext-file=chef_alertmanager.yml.enc --plaintext-file=chef_alertmanager.yml
gcloud --project gitlab-pre kms encrypt --location=global --keyring=skarbek-test --key=skarbek-test --ciphertext-file=k8s_alertmanager.yml.enc --plaintext-file=k8s_alertmanager.yml
gsutil cp alertmanager.yml.enc gs://skarbek-test/chef_alertmanager.yml.enc
gsutil cp alertmanager.yml.enc gs://skarbek-test/k8s_alertmanager.yml.enc
