#!/bin/bash

set -e

# ==================================================
# LabX Credentials
# ==================================================

LABX_PASSWORD="${LABX_PASSWORD:-labx@123}"

export PASSWORD="$LABX_PASSWORD"

# ==================================================
# Header
# ==================================================

echo ""
echo "=========================================="
echo "          LabX Python Environment"
echo "=========================================="
echo ""

echo "Python:"
python --version

echo ""
echo "Python executable:"
which python

echo ""
echo "Starting JupyterLab..."
echo "Starting LabX-Server..."
echo ""

# ==================================================
# Configure Jupyter password
# ==================================================

mkdir -p /root/.jupyter

LABX_PASSWORD="$LABX_PASSWORD" python -c '
import os
from pathlib import Path
from jupyter_server.auth import passwd

password = os.environ["LABX_PASSWORD"]
password_hash = passwd(password)

Path("/root/.jupyter/jupyter_server_config.py").write_text(
    "c.ServerApp.password = " + repr(password_hash) + "\n"
)
'

# ==================================================
# JupyterLab
#
# Container: 8888
# Host:      5959
# ==================================================

jupyter lab \
    --ip=0.0.0.0 \
    --port=5959 \
    --no-browser \
    --allow-root \
    --ServerApp.password_required=True \
    > /tmp/jupyter.log 2>&1 &

JUPYTER_PID=$!

# ==================================================
# LabX-Server
#
# Container: 8080
# Host:      5960
# ==================================================

LabX-Server \
    --bind-addr 0.0.0.0:5960 \
    --auth password \
    --app-name "LabX-Server" \
    --i18n /etc/labx/i18n.json \
    /workspace \
    > /tmp/labx-server.log 2>&1 &

LABX_SERVER_PID=$!

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
echo "  Password: ${LABX_PASSWORD}"

echo ""
echo "LabX-Server:"
echo "  http://localhost:5960"
echo "  Password: ${LABX_PASSWORD}"

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
        echo ""
        cat /tmp/jupyter.log
        exit 1
    fi

    if ! kill -0 "$LABX_SERVER_PID" 2>/dev/null; then
        echo "ERROR: LabX-Server stopped."
        echo ""
        cat /tmp/labx-server.log
        exit 1
    fi

    sleep 5

done