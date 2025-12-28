#!/bin/bash

set -e

step-ca /home/step/config/ca.json \
    --password-file /home/step/secrets/ca-password
