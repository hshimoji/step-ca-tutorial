#!/bin/bash

set -e

step ca init \
    --name "tutorial-03 CA" \
    --dns "localhost" \
    --deployment-type standalone \
    --address ":9000" \
    --provisioner "admin" \
    --password-file ./secrets/ca-password
