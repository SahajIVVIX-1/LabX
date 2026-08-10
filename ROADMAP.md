# LabX Portable Python Runtime — Full Implementation Roadmap

Everything below assumes the files already generated: `Dockerfile.cpu`,
`Dockerfile.cuda`, `requirements-linux.txt`, `labx` / `labx.ps1`,
`.devcontainer/devcontainer.json`, `.github/workflows/build-publish.yml`.

---

## Phase 0 — Prerequisites (do once, on your main dev machine)

1. Install **Docker Desktop** (Windows/macOS) or **Docker Engine** (Linux).
2. Install **Git**, and make sure you're logged into GitHub.
3. Create a new **GitHub repository** — e.g. `labx`. Public or private both
   work with GHCR; private just means other machines need `docker login
   ghcr.io` before pulling.
4. On GitHub: **Settings → Actions → General → Workflow permissions** → set
   to "Read and write permissions". This is what lets the Actions workflow
   push images to GHCR using the automatic `GITHUB_TOKEN` (no extra secret
   needed).

---

## Phase 1 — Assemble the repo

1. Create this folder structure locally and `git init`:
   ```
   labx/
   ├── Dockerfile.cpu
   ├── Dockerfile.cuda
   ├── requirements-linux.txt
   ├── labx                (chmod +x)
   ├── labx.ps1
   ├── .devcontainer/
   │   └── devcontainer.json
   ├── .github/
   │   └── workflows/
   │       └── build-publish.yml
   └── README.md
   ```
2. In every file, replace `SahajIVVIX-1` / `ghcr.io/SahajIVVIX-1/labx` with your
   actual GitHub username or org and repo name.
3. `git add . && git commit -m "Initial LabX Docker environment" && git push`
   to your new GitHub repo.

---

## Phase 2 — Build and test locally (before touching CI)

Do this first so you're not debugging a broken environment definition inside
GitHub Actions, where iteration is much slower.

1. **Build the CPU image:**
   ```bash
   docker build -f Dockerfile.cpu -t labx:cpu-dev .
   ```
   Watch for `pip install` failures — with 371 packages, a handful may need
   a missing system library or a version bump. Fix and rebuild until it
   completes cleanly. (`docker build` caches layers, so re-running after a
   small `requirements-linux.txt` fix is fast.)

2. **Sanity-check the interpreter:**
   ```bash
   docker run --rm labx:cpu-dev --version
   # Expect: Python 3.13.14
   ```

3. **Run a real script through it**, from an arbitrary folder, to confirm
   the mount pattern works:
   ```bash
   echo 'import numpy, pandas, sklearn, cv2; print("ok")' > /tmp/test.py
   docker run --rm -v /tmp:/workspace -w /workspace \
     --entrypoint python labx:cpu-dev test.py
   ```

4. **Test Jupyter:**
   ```bash
   docker run --rm -p 8888:8888 -v "$(pwd)":/workspace -w /workspace \
     --entrypoint jupyter labx:cpu-dev lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
   ```
   Open the printed `localhost:8888` URL, create a notebook, confirm it runs
   on Python 3.13.14 with the LabX kernel.

5. **Build and test the GPU image** (only if you have an NVIDIA GPU +
   NVIDIA Container Toolkit installed):
   ```bash
   docker build -f Dockerfile.cuda -t labx:cuda-dev .
   docker run --rm --gpus all --entrypoint python labx:cuda-dev -c \
     "import torch, tensorflow as tf; print(torch.cuda.is_available()); print(tf.config.list_physical_devices('GPU'))"
   ```

Don't move to Phase 3 until both builds succeed and the smoke tests pass —
everything downstream (CLI, VS Code, CI) just wraps this same image.

---

## Phase 3 — Set up the `labx` CLI

1. **macOS/Linux:**
   ```bash
   cp labx /usr/local/bin/labx
   chmod +x /usr/local/bin/labx
   ```
2. **Windows (PowerShell):** copy `labx.ps1` and the `labx.cmd` wrapper
   (shown in the comment at the bottom of `labx.ps1`) into a folder on your
   `PATH`, e.g. `C:\Tools\labx\`.
3. Test it against your locally built dev image first by setting:
   ```bash
   export LABX_IMAGE=labx        # macOS/Linux
   export LABX_TAG=cpu-dev
   ```
   ```powershell
   $env:LABX_IMAGE = "labx"      # Windows
   $env:LABX_TAG = "cpu-dev"
   ```
   Then: `labx python /tmp/test.py`, `labx jupyter`, `labx shell`.
4. Once GHCR images exist (Phase 5), unset these overrides so `labx`
   defaults back to `ghcr.io/SahajIVVIX-1/labx:latest`.

---

## Phase 4 — VS Code integration

1. Install the **Dev Containers** extension in VS Code.
2. Open any project folder that has (or that you copy)
   `.devcontainer/devcontainer.json` into it.
3. Command Palette → **"Dev Containers: Reopen in Container"**.
4. VS Code rebuilds its server inside the container on first run (slower
   once), then attaches. Verify:
   - Terminal → `python --version` → `3.13.14`
   - Open a `.py` file → **Run Python File** → should execute inside the
     container
   - Set a breakpoint → **Start Debugging** → should stop inside the
     container's Python
   - Open a `.ipynb` file → select the LabX kernel → run a cell
5. For GPU projects, uncomment the `runArgs: ["--gpus", "all"]` line and
   point `image` at the `-cuda` tag.

---

## Phase 5 — Wire up GitHub Actions → GHCR

1. Confirm `.github/workflows/build-publish.yml` is pushed to the repo
   (Phase 1).
2. Tag your first release:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Go to the **Actions** tab on GitHub — watch `build-cpu` and `build-gpu`
   run. First build will take a while (large images, no cache yet);
   subsequent builds are faster via the `type=gha` layer cache.
4. Once green, check **Packages** on your GitHub profile/org — you should
   see `labx:v1.0.0`, `labx:latest`, `labx:v1.0.0-cuda`, `labx:latest-cuda`.
5. If the package is private, set its visibility (Package settings →
   Danger Zone → Change visibility) or grant repo access, depending on who
   needs to pull it.

---

## Phase 6 — Validate true portability on a second machine

This is the real end-to-end test — don't skip it.

1. On a **different machine** (or a clean VM): install Docker only.
2. If the GHCR package is private:
   ```bash
   echo <a GitHub PAT with read:packages> | docker login ghcr.io -u <username> --password-stdin
   ```
3. ```bash
   docker pull ghcr.io/SahajIVVIX-1/labx:v1.0.0
   ```
4. Copy the `labx` CLI script over (it's the one thing that isn't inside
   the image) and run:
   ```bash
   labx python some_script.py
   labx jupyter
   ```
5. Copy `.devcontainer/devcontainer.json` into a project on this machine,
   open it in VS Code, **Reopen in Container**, confirm everything works
   identically to Phase 4.

If this phase works cleanly, the architecture is proven: no manual Python
or package installation happened on this second machine at all.

---

## Phase 7 — Ongoing update workflow

Whenever you need to add/upgrade a package:

1. Edit `requirements-linux.txt` (or the `torch`/`tensorflow` pins in the
   Dockerfile) in the repo.
2. Rebuild and smoke-test **locally** first (Phase 2, steps 1–3) — cheaper
   and faster than debugging inside Actions.
3. Commit the change.
4. Bump the version and tag:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```
5. Actions builds and publishes automatically. `latest` moves forward;
   `v1.0.0` stays exactly as it was.
6. On any other machine: `labx pull` (defaults to `latest`) or
   `docker pull ghcr.io/SahajIVVIX-1/labx:v1.1.0` to get the update.

---

## Phase 8 — Rollback

No rebuild needed — old tags are immutable in GHCR.

- **CLI:** `labx --tag v1.0.0 python script.py`
- **VS Code:** change `"image"` in `devcontainer.json` to
  `ghcr.io/SahajIVVIX-1/labx:v1.0.0`, then **Reopen in Container**.
- **Plain Docker:** `docker pull ghcr.io/SahajIVVIX-1/labx:v1.0.0` and use
  that tag directly.

---

## Phase 9 — Ongoing housekeeping (optional but worth planning for)

- **GHCR storage growth:** each version tag keeps its full image; set a
  retention policy (GitHub → Package settings) if old versions pile up, or
  prune manually, keeping at least your last few known-good tags.
- **Periodically re-verify Python/package compatibility** when you bump
  major libraries (PyTorch, TensorFlow especially) — repeat the audit
  process from before you build, not after.
- **Keep a CHANGELOG** of what changed between versions, since `git log`
  between tags plus your requirements diff is the only record of what's
  actually inside each image tag.

---

## Summary checklist

- [ ] Docker installed, GitHub repo created, Actions write permissions set
- [ ] Repo assembled with all files, `SahajIVVIX-1` placeholders replaced
- [ ] CPU image builds and passes smoke tests locally
- [ ] GPU image builds and passes smoke tests locally (if applicable)
- [ ] `labx` CLI installed and tested against local dev image
- [ ] VS Code Dev Containers verified: run, debug, notebook kernel, terminal
- [ ] `v1.0.0` tag pushed, Actions build green, images visible in GHCR
- [ ] Pulled and used successfully on a second, clean machine
- [ ] Update workflow tested (bump → tag → pull elsewhere)
- [ ] Rollback tested (old tag still works)
