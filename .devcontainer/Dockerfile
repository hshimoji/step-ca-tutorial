FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Install necessary packages for installation steps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install just
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install step and step-ca
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    STEP_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
    STEP_ARCH="arm64"; \
    else \
    echo "Unsupported architecture: $ARCH"; \
    exit 1; \
    fi && \
    curl -LO "https://dl.smallstep.com/cli/docs-ca-install/latest/step_linux_${STEP_ARCH}.tar.gz" && \
    tar -zxf "step_linux_${STEP_ARCH}.tar.gz" -C /usr/local/bin --strip-components=2 "step_linux_${STEP_ARCH}/bin/step" && \
    curl -LO "https://dl.smallstep.com/certificates/docs-ca-install/latest/step-ca_linux_${STEP_ARCH}.tar.gz" && \
    tar -zxf "step-ca_linux_${STEP_ARCH}.tar.gz" -C /usr/local/bin --strip-components=1 "step-ca_linux_${STEP_ARCH}/step-ca" && \
    chown root:root /usr/local/bin/step* && \
    rm -f *.tar.gz

# Install step-kms-plugin for Cloud KMS support
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    STEP_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
    STEP_ARCH="arm64"; \
    else \
    echo "Unsupported architecture: $ARCH"; \
    exit 1; \
    fi && \
    PLUGIN_VERSION="0.16.0" && \
    curl -L "https://github.com/smallstep/step-kms-plugin/releases/download/v${PLUGIN_VERSION}/step-kms-plugin_${PLUGIN_VERSION}_linux_${STEP_ARCH}.tar.gz" -o /tmp/step-kms-plugin.tar.gz && \
    tar -xzf /tmp/step-kms-plugin.tar.gz -C /tmp && \
    mv /tmp/step-kms-plugin_${PLUGIN_VERSION}/step-kms-plugin /usr/local/bin/ && \
    chmod +x /usr/local/bin/step-kms-plugin && \
    rm -rf /tmp/step-kms-plugin*

# Install Google Cloud CLI and jq
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    jq \
    google-cloud-cli \
    libpcsclite1 \
    && rm -rf /var/lib/apt/lists/*

# Setup completions
RUN mkdir -p /etc/bash_completion.d && \
    step completion bash > /etc/bash_completion.d/step


