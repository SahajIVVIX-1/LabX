# labx.ps1 — run scripts / Jupyter / a shell inside the LabX Docker Python runtime
# Install: copy somewhere on your PATH, e.g. C:\Tools\labx\labx.ps1
#          then create a small labx.cmd wrapper (see bottom of this file) so
#          `labx` works directly from cmd.exe / PowerShell without ".ps1".

param(
    [Parameter(Position = 0)] [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)] [string[]]$Rest
)

$Image = if ($env:LABX_IMAGE) { $env:LABX_IMAGE } else { "ghcr.io/SahajIVVIX-1/labx" }
$Tag = if ($env:LABX_TAG) { $env:LABX_TAG } else { "latest" }
$Gpu = $false

# Pull --gpu / --tag flags out of $Rest if present
$filtered = @()
for ($i = 0; $i -lt $Rest.Count; $i++) {
    if ($Rest[$i] -eq "--gpu") { $Gpu = $true; continue }
    if ($Rest[$i] -eq "--tag") { $Tag = $Rest[$i + 1]; $i++; continue }
    $filtered += $Rest[$i]
}
$Rest = $filtered

if ($Gpu) {
    $Image = if ($env:LABX_IMAGE_GPU) { $env:LABX_IMAGE_GPU } else { "$Image-cuda" }
    $GpuFlag = "--gpus", "all"
} else {
    $GpuFlag = @()
}

$FullImage = "${Image}:${Tag}"

function Show-Usage {
@"
labx — run things inside the LabX Docker Python 3.13.14 runtime

Usage:
  labx python <script.py> [args...]
  labx jupyter
  labx shell
  labx pull [tag]
  labx version

Options:
  --gpu           Use the GPU/CUDA image variant
  --tag <tag>     Use a specific image version (rollback), e.g. v1.0.0
"@ | Write-Host
}

switch ($Command) {
    "python" {
        $Script = $Rest[0]
        $ScriptArgs = $Rest[1..($Rest.Count - 1)]
        $AbsPath = (Resolve-Path $Script).Path
        $Dir = Split-Path $AbsPath -Parent
        $File = Split-Path $AbsPath -Leaf
        docker run --rm -it @GpuFlag `
            -v "${Dir}:/workspace" `
            -w /workspace `
            --entrypoint python `
            $FullImage $File @ScriptArgs
    }
    "jupyter" {
        docker run --rm -it @GpuFlag `
            -v "${PWD}:/workspace" `
            -w /workspace `
            -p 8888:8888 `
            --entrypoint jupyter `
            $FullImage lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
    }
    "shell" {
        docker run --rm -it @GpuFlag `
            -v "${PWD}:/workspace" `
            -w /workspace `
            --entrypoint bash `
            $FullImage
    }
    "pull" {
        $PullTag = if ($Rest.Count -gt 0) { $Rest[0] } else { $Tag }
        docker pull "${Image}:${PullTag}"
    }
    "version" {
        docker run --rm --entrypoint python $FullImage --version
    }
    default {
        Show-Usage
    }
}

<#
Optional: labx.cmd wrapper so plain `labx` works from any shell.
Save this as labx.cmd next to labx.ps1:

    @echo off
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0labx.ps1" %*
#>
