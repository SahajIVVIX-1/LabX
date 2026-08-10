FROM python:3.11.9-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /workspace

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
    ipykernel

# ==================================================
# Register LabX Python kernel
# ==================================================

RUN python -m ipykernel install \
    --sys-prefix \
    --name labx-python \
    --display-name "LabX Python 3.11.9"

# ==================================================
# code-server
# ==================================================

RUN curl -fsSL https://code-server.dev/install.sh | sh

# Verify code-server installation
RUN code-server --version

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
    echo "  $extension"; \
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
#   8080 -> Web VS Code
#
# Host:
#   5959 -> JupyterLab
#   5960 -> Web VS Code
# ==================================================

EXPOSE 8888
EXPOSE 8080

# ==================================================
# Start
# ==================================================

CMD ["/usr/local/bin/start.sh"]