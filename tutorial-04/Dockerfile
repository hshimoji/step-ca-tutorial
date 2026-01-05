FROM smallstep/step-ca:latest

# Switch to root to install packages
USER root

# Install step-kms-plugin for Cloud KMS support
RUN apk add --no-cache curl && \
    PLUGIN_VERSION="v0.11.7" && \
    PLUGIN_VERSION_NUMBER="${PLUGIN_VERSION:1}" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -L "https://github.com/smallstep/step-kms-plugin/releases/download/${PLUGIN_VERSION}/step-kms-plugin_${PLUGIN_VERSION_NUMBER}_linux_${ARCH}.tar.gz" -o /tmp/step-kms-plugin.tar.gz && \
    tar -xzf /tmp/step-kms-plugin.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/step-kms-plugin && \
    rm /tmp/step-kms-plugin.tar.gz && \
    step-kms-plugin version

# Switch back to step user
USER step
