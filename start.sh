#!/bin/bash

set -e

# ==================================================
# LabX Credentials
# ==================================================

LABX_PASSWORD="${LABX_PASSWORD:-labx@123}"

echo ""
echo "=========================================="
echo "        LabX Python Environment"
echo "=========================================="
echo ""

echo "Python:"
python --version

echo ""
echo "Python executable:"
which python

echo ""
echo "Starting JupyterLab..."
echo "Starting Web VS Code..."
echo ""

# ==================================================
# Configure Jupyter password
# ==================================================

mkdir -p /root/.jupyter

python -c "
from jupyter_server.auth import passwd
from pathlib import Path

password_hash = passwd('$LABX_PASSWORD')

Path('/root/.jupyter/jupyter_server_config.py').write_text(
    'c.ServerApp.password = ' + repr(password_hash) + '\n'
)
"

# ==================================================
# JupyterLab
# Container port: 8888
# Host port: 5959
# ==================================================

jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.password_required=True \
    > /tmp/jupyter.log 2>&1 &

JUPYTER_PID=$!

# ==================================================
# Web VS Code
# Container port: 8080
# Host port: 5960
# ==================================================

export PASSWORD="$LABX_PASSWORD"

code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    /workspace \
    > /tmp/code-server.log 2>&1 &

CODE_SERVER_PID=$!

# ==================================================
# Wait for services
# ==================================================

sleep 3

echo ""
echo "=========================================="
echo "             LabX is running"
echo "=========================================="
echo ""

echo "Python:"
echo "  $(python --version 2>&1)"

echo ""
echo "JupyterLab:"
echo "  http://localhost:5959"
echo "  Password: labx@123"

echo ""
echo "Web VS Code:"
echo "  http://localhost:5960"
echo "  Password: labx@123"

echo ""
echo "Workspace:"
echo "  /workspace"

echo ""
echo "=========================================="
echo ""

# ==================================================
# Monitor services
# ==================================================

while true; do

    if ! kill -0 "$JUPYTER_PID" 2>/dev/null; then
        echo "ERROR: JupyterLab stopped."
        cat /tmp/jupyter.log
        exit 1
    fi

    if ! kill -0 "$CODE_SERVER_PID" 2>/dev/null; then
        echo "ERROR: code-server stopped."
        cat /tmp/code-server.log
        exit 1
    fi

    sleep 5

done