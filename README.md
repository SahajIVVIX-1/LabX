# LabX Docker Runtime — build files

## Files in this batch

- `requirements-linux.txt` — your `LabX-Global` package list, filtered for Linux/Python 3.13.14:
  - 55 Windows-only and GUI/desktop-automation packages removed (full list in the previous message)
  - `pip`, `setuptools`, `wheel` unpinned (base image manages these)
  - `opencv-python` → `opencv-python-headless` (no display server in a container)
  - `torch`/`torchvision`/`torchaudio` removed from this file — installed separately in each Dockerfile because CPU and GPU builds need different wheel indexes
  - 4 packages flagged as likely private/local and left out entirely: `student-perf` (your local editable project — don't bake this into the base image, mount it instead), `styles`, `uncalled-for`, `config` — verify these are really meant to be here before adding them back
- `Dockerfile.cpu` — CPU-only image, `python:3.13.14-slim-bookworm` base
- `Dockerfile.cuda` — GPU image, `nvidia/cuda:12.6.0-cudnn-devel-ubuntu24.04` base + Python 3.13.14 via deadsnakes

## Build locally to test before wiring up CI

```bash
# CPU
docker build -f Dockerfile.cpu -t labx:cpu-dev .

# GPU (needs NVIDIA Container Toolkit on the build host)
docker build -f Dockerfile.cuda -t labx:cuda-dev .
```

## Quick smoke test

```bash
# Check the interpreter version
docker run --rm labx:cpu-dev --version
# -> should print Python 3.13.14

# Run a script from an arbitrary host folder
docker run --rm -v "$(pwd)":/workspace -w /workspace labx:cpu-dev script.py

# GPU: confirm CUDA is visible inside the container
docker run --rm --gpus all --entrypoint python labx:cuda-dev -c \
  "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

## What to verify before treating this as production-ready

1. **Full `pip install -r requirements-linux.txt` build succeeds** — with 371 packages there's a real chance one or two have version-specific build quirks on Linux/3.13.14 that only show up at install time (native-extension packages in particular: `faiss-cpu`, `catboost`, `lightgbm`, `pyarrow`). Run the build and fix any that fail one at a time rather than guessing in advance.
2. **TensorFlow Keras import paths** — smoke-test `from tensorflow.keras.layers import Dense` and your actual model code; TF 2.20's Keras 3 split has caused import-path issues for some users independent of the Python version.
3. **CUDA version match** — cu126 is used here as a reasonable current pin; check it against your actual GPU driver's supported CUDA version before building the GPU image, and adjust the `--index-url` CUDA suffix if needed.
4. **deadsnakes patch pinning** — see the note at the bottom of `Dockerfile.cuda`; this is the one part of the GPU build most likely to need adjustment over time.

## Next steps in the roadmap

Once both images build and the smoke tests pass, the remaining pieces are:
- the `labx` host CLI (for `labx python script.py` from anywhere)
- `.devcontainer/devcontainer.json` for VS Code
- the GitHub Actions workflow that builds/tags/pushes to GHCR on version tags
