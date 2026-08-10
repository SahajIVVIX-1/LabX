# LabX — Task Brief for Google Antigravity

Give the agent the files already produced (`Dockerfile.cpu`, `Dockerfile.cuda`,
`requirements-linux.txt`, `labx`, `labx.ps1`, `.devcontainer/devcontainer.json`,
`.github/workflows/build-publish.yml`, `README.md`, `ROADMAP.md`) as the
starting point, then run the sub-tasks below **one at a time**, in order.
Agentic tools do best on scoped, independently-verifiable tasks rather than
one giant instruction — Antigravity in particular is built around
plan → execute → verify per task, so splitting it up plays to its strengths
and gives you a clear checkpoint to review before it moves on.

---

## What you do yourself first (the agent can't do these)

1. Install Docker Desktop / Docker Engine on the machine Antigravity will
   run commands on.
2. Create the GitHub repo (e.g. `labx`) and give Antigravity access to it
   (it works inside a local folder connected to git — clone the repo
   locally first).
3. In the repo's GitHub settings: **Actions → General → Workflow
   permissions → Read and write permissions** (required for GHCR push).
4. If you want GPU support: confirm you actually have an NVIDIA GPU with
   the NVIDIA Container Toolkit installed. If not, tell the agent to skip
   all GPU/CUDA tasks — no point having it build something you can't test.
5. Decide on your GHCR namespace (`ghcr.io/<your-username>/labx`) and give
   that exact string to the agent — don't let it guess.

---

## Task 1 — Repo assembly and placeholder fix

**Prompt for the agent:**
> Place the provided files into this repo in the structure: `Dockerfile.cpu`,
> `Dockerfile.cuda`, `requirements-linux.txt`, `labx`, `labx.ps1`,
> `.devcontainer/devcontainer.json`, `.github/workflows/build-publish.yml`,
> `README.md`. Replace every occurrence of `<your-org>` with `<your actual
> GitHub username/org>` across all files. Make `labx` executable. Commit and
> push to `main`.

**Verify:** ask the agent to `grep -r "<your-org>"` across the repo and
confirm zero matches before it commits.

---

## Task 2 — Build and fix the CPU image locally

**Prompt for the agent:**
> Run `docker build -f Dockerfile.cpu -t labx:cpu-dev .` in this repo. If
> the build fails on any package in `requirements-linux.txt`, investigate
> the actual error (missing system library, version conflict, etc.), fix
> `Dockerfile.cpu` or the package version, and rebuild. Repeat until the
> build succeeds. Do not silently delete failing packages from the
> requirements file without telling me which ones and why.

This is the step most likely to need real iteration — 371 packages, some
with native extensions, is exactly the kind of "run it, read the error, fix
it, run it again" loop agents are good at and you don't want to do by hand.

**Verify:**
> Run `docker run --rm labx:cpu-dev --version` and confirm it prints
> `Python 3.11.9`. Run a script importing numpy, pandas, sklearn, cv2,
> torch, tensorflow inside the container and confirm no import errors.

---

## Task 3 — Build and fix the GPU image (skip if no GPU)

Same pattern as Task 2, pointed at `Dockerfile.cuda`, with the agent also
verifying `torch.cuda.is_available()` returns `True` and
`tf.config.list_physical_devices('GPU')` shows the device.

---

## Task 4 — Jupyter smoke test

**Prompt for the agent:**
> Start JupyterLab from `labx:cpu-dev` using the `labx jupyter` command
> (set `LABX_IMAGE=labx`, `LABX_TAG=cpu-dev` as env vars first), confirm
> the server starts and is reachable on `localhost:8888`, then create and
> run a trivial notebook cell to confirm the kernel executes.

Antigravity can drive a browser as part of verification — this is a good
place to let it actually open the Jupyter URL and confirm it loads rather
than just checking the process started.

---

## Task 5 — VS Code Dev Container check

**Prompt for the agent:**
> Verify `.devcontainer/devcontainer.json` is valid JSON and points at the
> correct image name. If VS Code and the Dev Containers extension are
> available in this environment, open the folder in a container and
> confirm `python --version` reports 3.11.9 in the integrated terminal.

If Antigravity's environment can't actually launch VS Code, have it stop
at "config is valid" and do the live check yourself once — this is a good
manual checkpoint since it's the part you'll interact with daily.

---

## Task 6 — GitHub Actions dry run

**Prompt for the agent:**
> Validate `.github/workflows/build-publish.yml` (YAML syntax, correct
> image name, correct registry). Do not push a version tag yet — wait for
> my confirmation.

Push the actual `v1.0.0` tag **yourself** the first time, since it triggers
a real, potentially slow/costly CI run and publishes a real public/private
package — worth being the one to pull that trigger rather than delegating
it, even if the agent prepared everything.

**Then, after you tag and push:**
> Watch the Actions run (or poll via `gh run list` / `gh run watch` if the
> GitHub CLI is available) and report whether `build-cpu` and `build-gpu`
> succeeded. If either failed, diagnose from the logs and propose a fix.

---

## Task 7 — Second-machine portability test

This is the one that actually proves the architecture works — don't skip
delegating it just because it's the last step.

**Prompt for the agent (run on a second machine/VM if you can give it
access, otherwise simulate by removing local image cache first):**
> Starting from a machine with only Docker installed, pull
> `ghcr.io/<you>/labx:v1.0.0`, copy over just the `labx` CLI script, and run
> `labx python <test script>` and `labx jupyter`. Confirm both work with no
> other setup performed.

---

## How to sequence this in Antigravity specifically

- Use the **Agent Manager** to run Task 2 and Task 3 as separate parallel
  agents once Task 1 is done — they don't depend on each other and both
  involve real wait time (image builds), so running them concurrently
  saves you time.
- Review each task's **Artifact/verification output** before approving the
  next task that depends on it — especially Task 2, since Tasks 4–7 all
  build on that image existing and working.
- Keep Task 6's tag-push as a manual step (see above) — everything else is
  safe to fully delegate.

---

## What "done" looks like

- [ ] Repo pushed, no `<your-org>` placeholders left
- [ ] `labx:cpu-dev` builds clean and passes import/version smoke tests
- [ ] `labx:cuda-dev` builds clean and reports GPU visible (if applicable)
- [ ] Jupyter reachable and runs a cell inside the container
- [ ] `devcontainer.json` validated (and live-tested by you in VS Code)
- [ ] `v1.0.0` tagged, Actions green, images visible in GHCR
- [ ] Pulled and run successfully with zero manual setup on a second machine