#!/bin/bash

set -e

step ca init \
    --name "tutorial-01 CA" \
    --dns "localhost" \
    --deployment-type standalone \
    --address ":9000" \
    --provisioner "admin"
    