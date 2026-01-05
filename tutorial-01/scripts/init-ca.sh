#!/bin/bash

set -e

mkdir -p ./secrets
step crypto rand 2 > ./secrets/ca-password
step ca init \
    --name "tutorial-01 CA" \
    --dns "localhost" \
    --deployment-type standalone \
    --address ":9000" \
    --provisioner "admin" \
    --password-file ./secrets/ca-password
