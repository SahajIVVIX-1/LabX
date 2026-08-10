# syntax=docker/dockerfile:1

FROM python:3.11.9-slim-bookworm

# ==================================================
# Build arguments
# ==================================================

ARG CODE_SERVER_VERSION=4.132.0
ARG TARGETARCH

# ==================================================
# Environment
# ==================================================

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CODE_SERVER_APP_NAME="LabX-Server"

WORKDIR /workspace

# ==================================================
# Terminal prompt
# ==================================================

RUN echo 'export PS1="\u@labx:\w\$ "' >> /root/.bashrc

# ==================================================
# System dependencies
# ==================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    build-essential \
    ffmpeg \
    graphviz \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ==================================================
# Upgrade pip
# ==================================================

RUN python -m pip install --upgrade pip

# ==================================================
# Jupyter
# ==================================================

RUN pip install \
    jupyterlab \
    notebook \
    ipykernel \
    jupyterlab-tailwind-theme

# ==================================================
# JupyterLab default settings
# ==================================================

RUN mkdir -p /usr/local/share/jupyter/lab/settings

COPY jupyter/override.json \
    /usr/local/share/jupyter/lab/settings/overrides.json

# ==================================================
# Register LabX Python kernel
# ==================================================

RUN python -m ipykernel install \
    --sys-prefix \
    --name labx-python \
    --display-name "LabX Python 3.11.9"

# ==================================================
# Install pinned code-server v4.132.0
# ==================================================

RUN set -eux; \
    case "${TARGETARCH}" in \
    amd64) CS_ARCH="amd64" ;; \
    arm64) CS_ARCH="arm64" ;; \
    *) \
    echo "Unsupported architecture: ${TARGETARCH}"; \
    exit 1 \
    ;; \
    esac; \
    mkdir -p /opt/code-server; \
    curl -fL \
    "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-${CS_ARCH}.tar.gz" \
    -o /tmp/code-server.tar.gz; \
    tar -xzf /tmp/code-server.tar.gz \
    -C /opt/code-server \
    --strip-components=1; \
    rm -f /tmp/code-server.tar.gz; \
    ln -sf /opt/code-server/bin/code-server \
    /usr/local/bin/code-server; \
    ln -sf /opt/code-server/bin/code-server \
    /usr/local/bin/LabX-Server; \
    code-server --version; \
    LabX-Server --version

# ==================================================
# LabX logo
# ==================================================

COPY branding/logo.png /tmp/labx-logo.png

# ==================================================
# Locate code-server branding directories
# ==================================================

RUN set -eux; \
    MEDIA_DIR="$(find /opt/code-server -type d -path '*/src/browser/media' -print -quit)"; \
    PAGE_DIR="$(find /opt/code-server -type d -path '*/src/browser/pages' -print -quit)"; \
    \
    if [ -z "$MEDIA_DIR" ]; then \
    echo "ERROR: code-server media directory not found"; \
    exit 1; \
    fi; \
    \
    if [ -z "$PAGE_DIR" ]; then \
    echo "ERROR: code-server pages directory not found"; \
    exit 1; \
    fi; \
    \
    echo "========================================"; \
    echo "LabX branding"; \
    echo "Media: $MEDIA_DIR"; \
    echo "Pages: $PAGE_DIR"; \
    echo "========================================"; \
    \
    cp /tmp/labx-logo.png "$MEDIA_DIR/labx-logo.png"; \
    cp /tmp/labx-logo.png "$MEDIA_DIR/pwa-icon-192.png"; \
    cp /tmp/labx-logo.png "$MEDIA_DIR/pwa-icon-512.png"; \
    \
    rm -f /tmp/labx-logo.png

# ==================================================
# VS Code extensions
#
# Automatically install EVERY .vsix file
# inside vscode/vsix/
# ==================================================

COPY vscode/vsix/ /tmp/vsix/

RUN set -eux; \
    found=0; \
    for extension in /tmp/vsix/*.vsix; do \
    if [ -f "$extension" ]; then \
    found=1; \
    echo "========================================"; \
    echo "Installing VS Code extension:"; \
    echo "$extension"; \
    echo "========================================"; \
    code-server --install-extension "$extension"; \
    fi; \
    done; \
    if [ "$found" -eq 0 ]; then \
    echo "No VSIX extensions found."; \
    fi; \
    rm -rf /tmp/vsix

# ==================================================
# VS Code settings
# ==================================================

RUN mkdir -p /root/.local/share/code-server/User

COPY vscode/settings.json \
    /root/.local/share/code-server/User/settings.json

# ==================================================
# LabX custom login strings
# ==================================================

RUN mkdir -p /etc/labx

RUN cat > /etc/labx/i18n.json <<'EOF'
{
    "LOGIN_TITLE": "LabX-Server Login",
    "LOGIN_BELOW": "Sign in to LabX-Server.",
    "WELCOME": "Welcome to LabX-Server",
    "LOGIN_PASSWORD": "Enter your LabX-Server password.",
    "LOGIN_USING_ENV_PASSWORD": "Password authentication is enabled.",
    "LOGIN_USING_HASHED_PASSWORD": "Password authentication is enabled.",
    "SUBMIT": "SIGN IN",
    "PASSWORD_PLACEHOLDER": "LABX PASSWORD",
    "LOGIN_RATE_LIMIT": "Login rate limited!",
    "MISS_PASSWORD": "Password is required.",
    "INCORRECT_PASSWORD": "Incorrect LabX-Server password."
}
EOF

# ==================================================
# Workspace
# ==================================================

RUN mkdir -p /workspace

# ==================================================
# Startup script
# ==================================================

COPY start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

# ==================================================
# Ports
#
# Container:
#   8888 -> JupyterLab
#   8080 -> LabX-Server
#
# Host:
#   5959 -> JupyterLab
#   5960 -> LabX-Server
# ==================================================

EXPOSE 8888
EXPOSE 8080

# ==================================================
# Start
# ==================================================

CMD ["/usr/local/bin/start.sh"]