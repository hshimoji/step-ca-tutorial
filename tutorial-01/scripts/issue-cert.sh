#!/bin/bash

step ca certificate localhost localhost.crt localhost.key \
    --provisioner admin \
    --root /home/step/certs/root_ca.crt \
    --ca-url https://localhost:9000/