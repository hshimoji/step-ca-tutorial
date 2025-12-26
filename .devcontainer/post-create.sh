#!/usr/bin/env bash

STEP_VERSION=0.29.0

# Install just: https://github.com/casey/just?tab=readme-ov-file#pre-built-binaries
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# Install step and step-ca: https://smallstep.com/docs/step-ca/installation/#linux-binaries
#curl -fsSL -o step.tgz https://dl.smallstep.com/gh-release/cli/gh-release-header/v${STEP_VERSION}/step_linux_${STEP_VERSION}_amd64.tar.gz && \
curl -LO https://dl.smallstep.com/cli/docs-ca-install/latest/step_linux_amd64.tar.gz && \
    sudo tar -zxf step_linux_amd64.tar.gz -C /usr/local/bin --strip-components=2 step_linux_amd64/bin/step

curl -LO https://dl.smallstep.com/certificates/docs-ca-install/latest/step-ca_linux_amd64.tar.gz && \
    sudo tar -zxf step-ca_linux_amd64.tar.gz -C /usr/local/bin --strip-components=1 step-ca_linux_amd64/step-ca

sudo chown root:root /usr/local/bin/step*
rm -f *.tar.gz

step completion bash >> ~/.bashrc