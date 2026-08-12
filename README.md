<div align="center">
  <img src="branding/logo.png" alt="LabX Logo" width="140" />

  <h1>LabX</h1>

  <p><strong>A self-contained, Docker-powered Python development environment combining JupyterLab and a VS Code-compatible browser IDE in a single container.</strong></p>

  <p>
    <a href="https://www.python.org/downloads/release/python-3119/"><img src="https://img.shields.io/badge/Python-3.11.9-3776AB?logo=python&logoColor=white" alt="Python 3.11.9"/></a>
    <a href="https://jupyterlab.readthedocs.io/en/latest/"><img src="https://img.shields.io/badge/JupyterLab-4.6.2-F37626?logo=jupyter&logoColor=white" alt="JupyterLab 4.6.2"/></a>
    <a href="https://github.com/coder/code-server"><img src="https://img.shields.io/badge/code--server-4.132.0-0078D4?logo=visualstudiocode&logoColor=white" alt="code-server 4.132.0"/></a>
    <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white" alt="Docker"/></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"/></a>
  </p>
</div>

---

## 🧪 What is LabX?

**LabX** is a batteries-included Python lab environment that runs entirely inside Docker. With a single command you get:

| Tool | URL | Purpose |
|---|---|---|
| **JupyterLab** | `http://localhost:5959` | Interactive notebooks & data exploration |
| **LabX-Server** (code-server) | `http://localhost:5960` | Full VS Code IDE in the browser |

Both services share the same Python environment and `/workspace` directory, so code you write in one is immediately available in the other.

---

## ✨ Features

- 🐍 **Python 3.11.9** on a slim Debian (Bookworm) base
- 📓 **JupyterLab 4.6.2** with the *Simpledark* theme pre-configured
- 🖥️ **LabX-Server** (code-server 4.132.0) with custom branding, login strings, and a curated set of pre-installed VS Code extensions
- 📦 **Rich Python package stack** — NumPy, Pandas, Scikit-learn, PyTorch-ready (Keras, Transformers, Accelerate), OpenCV, NLTK, spaCy, MLflow, W&B, Stable-Baselines3, Gymnasium, and more
- 🔑 **Password-protected** — both services require authentication (default password configurable via env var)
- 🎨 **Custom branding** — LabX logo replaces all code-server icons and favicons
- 🔧 **17 pre-bundled VS Code extensions** installed offline from `.vsix` files, including Python, Jupyter, Prettier, Rainbow CSV, Database Client, Code Runner, and several themes
- 🏗️ **Multi-arch** — supports `linux/amd64` and `linux/arm64`
- 📁 **Persistent workspace** — mount a host directory to `/workspace` and your files persist across container restarts

---

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running

### 1 — Pull & Run (once published to a registry)

```bash
docker run -d \
  --name labx \
  -p 5959:5959 \
  -p 5960:5960 \
  -v "$(pwd)/workspace:/workspace" \
  -e LABX_PASSWORD=mysecretpassword \
  labx:latest
```

### 2 — Build from Source

```bash
git clone https://github.com/<your-org>/labx.git
cd labx

docker build -t labx:latest .
```

Then run the container:

```bash
docker run -d \
  --name labx \
  -p 5959:5959 \
  -p 5960:5960 \
  -v "$(pwd)/workspace:/workspace" \
  -e LABX_PASSWORD=mysecretpassword \
  labx:latest
```

### 3 — Open in your browser

| Service | URL |
|---|---|
| JupyterLab | [http://localhost:5959](http://localhost:5959) |
| LabX-Server | [http://localhost:5960](http://localhost:5960) |

Login with the password you set via `LABX_PASSWORD` (default: `labx@123`).

---

## ⚙️ Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `LABX_PASSWORD` | `labx@123` | Shared password for both JupyterLab and LabX-Server |

> **Tip:** Always set a strong custom password in production. Pass it with `-e LABX_PASSWORD=<your-password>` when running the container.

---

## 🐳 Docker Compose (recommended)

Create a `docker-compose.yml` in your project directory:

```yaml
services:
  labx:
    image: labx:latest
    container_name: labx
    ports:
      - "5959:5959"  # JupyterLab
      - "5960:5960"  # LabX-Server
    volumes:
      - ./workspace:/workspace
    environment:
      - LABX_PASSWORD=mysecretpassword
    restart: unless-stopped
```

Then start with:

```bash
docker compose up -d
```

---

## 📦 Pre-installed Python Packages

<details>
<summary>Click to expand full package list</summary>

| Category | Packages |
|---|---|
| **Core Science** | NumPy, SciPy, SymPy, Pandas |
| **Visualisation** | Matplotlib, Seaborn, Plotly |
| **Machine Learning** | Scikit-learn, MLflow, W&B (Weights & Biases) |
| **Deep Learning** | Keras, Transformers, Tokenizers, SentencePiece, Accelerate, Evaluate, Datasets |
| **Reinforcement Learning** | Gymnasium, Stable-Baselines3 |
| **Computer Vision** | OpenCV, Pillow, scikit-image, imageio |
| **NLP** | NLTK, spaCy, Gensim |
| **Utilities** | tqdm, joblib, requests, PyYAML, openpyxl, h5py, ipywidgets |

</details>

---

## 🔌 Pre-installed VS Code Extensions

| Extension | Purpose |
|---|---|
| `ms-python.python` | Python language support |
| `ms-toolsai.jupyter-hub` | JupyterHub integration |
| `ms-toolsai.jupyter-renderers` | Rich notebook output renderers |
| `formulahendry.code-runner` | Run code snippets in terminal |
| `esbenp.prettier-vscode` | Code formatter |
| `mechatroner.rainbow-csv` | Colourised CSV editing |
| `cweijan.vscode-database-client2` | Universal database GUI |
| `buvan.sql-crack` | SQL query runner |
| `ChristofKaufmann.dataframe-viewer` | DataFrame visual explorer |
| `julien-.terminal-file-actions` | File actions from terminal |
| `yandeu.five-server` | Live HTML/Markdown preview |
| `tuld01061.md-live-server` | Markdown live server |
| `the-long-ride.markdown-them` | Markdown theme |
| `Rafael-Avalos.dark-colors-theme` | Dark colour theme |
| `darkmusic.carbon-rewind-theme` | Carbon rewind theme |
| `mszylkowski.materialsymbols` | Material symbols icon font |
| `ryohidaka.github-actions-branding-preview` | GitHub Actions branding preview |

---

## 📁 Repository Structure

```
labx/
├── Dockerfile              # Main multi-stage Docker build
├── start.sh                # Container entrypoint — starts JupyterLab & LabX-Server
├── requirements.txt        # Top-level Python package list (unpinned)
├── requirements-linux.txt  # Fully pinned package list for Linux/Docker
├── branding/
│   └── logo.png            # LabX logo (applied to code-server UI)
├── jupyter/
│   └── overrides.json      # JupyterLab default theme settings
└── vscode/
    ├── settings.json       # Default VS Code / code-server user settings
    └── vsix/               # Pre-bundled VS Code extensions (.vsix)
```

---

## 🛠️ Ports Reference

| Port | Service | Notes |
|---|---|---|
| `5959` | JupyterLab | Mapped to the same host port |
| `5960` | LabX-Server | Mapped to the same host port |

---

## 🏗️ Building for Multiple Architectures

Use Docker Buildx to build for both `amd64` and `arm64`:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t labx:latest \
  --push .
```

---

## 🤝 Contributing

Contributions are welcome! Here are a few ways to help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/my-feature`)
3. **Commit** your changes (`git commit -m "feat: add my feature"`)
4. **Push** to your branch (`git push origin feature/my-feature`)
5. **Open** a Pull Request

Please keep commits focused and descriptive.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ by the LabX Contributors</sub>
</div>
