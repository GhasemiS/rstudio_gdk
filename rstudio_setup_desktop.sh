#!/usr/bin/env bash
# =============================================================================
# rstudio_setup_desktop.sh  —  Run this ONCE per user on desktop.genome.au.dk
# =============================================================================
# Usage:  bash rstudio_setup_desktop.sh
# Place this in your shared project rstudio/ folder, e.g.:
#   /faststorage/project/myProject/rstudio/
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
RSTUDIO_VERSION="4.2.2"
CONDA_ENV_YML_URL="https://raw.githubusercontent.com/GhasemiS/rstudio_gdk/refs/heads/main/rstudio_env.yml"
CONDA_ENV_NAME="rstudio_env"   # name defined inside the yml
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "========================================"
echo "  RStudio Server — One-time Setup"
echo "  (GenomeDK Desktop)"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "→ Working directory: $SCRIPT_DIR"
cd "$SCRIPT_DIR"

# ── 0. Initialise conda ───────────────────────────────────────────────────────
# When running as  bash script.sh  the shell is non-interactive, so conda's
# init block (added to ~/.bashrc) is never sourced.  Find and source it here.
CONDA_BASE=""
# Try the standard GenomeDK miniconda/anaconda locations first
for candidate in \
        "$HOME/miniconda3" \
        "$HOME/anaconda3" \
        "$HOME/miniforge3" \
        "/opt/conda" \
        "/usr/local/conda"; do
    if [[ -f "$candidate/etc/profile.d/conda.sh" ]]; then
        CONDA_BASE="$candidate"
        break
    fi
done
# Fall back to asking conda itself (works if it is on PATH somehow)
if [[ -z "$CONDA_BASE" ]] && command -v conda &>/dev/null; then
    CONDA_BASE="$(conda info --base 2>/dev/null || true)"
fi
if [[ -z "$CONDA_BASE" || ! -f "$CONDA_BASE/etc/profile.d/conda.sh" ]]; then
    echo "✗ Error: could not find a conda installation."
    echo "  Make sure miniconda/anaconda is installed under your home directory."
    exit 1
fi
source "$CONDA_BASE/etc/profile.d/conda.sh"
echo "✓ Conda initialised from: $CONDA_BASE"

# ── 1. Conda environment ──────────────────────────────────────────────────────
if conda env list | awk '{print $1}' | grep -qx "$CONDA_ENV_NAME"; then
    echo "✓ Conda environment '$CONDA_ENV_NAME' already exists — skipping."
else
    echo "→ Downloading conda environment file..."
    wget -q "$CONDA_ENV_YML_URL" -O "${CONDA_ENV_NAME}.yml"
    echo "→ Creating conda environment (this may take a few minutes)..."
    conda env create -f "${CONDA_ENV_NAME}.yml"
    echo "✓ Conda environment '$CONDA_ENV_NAME' created."
fi

# ── 2. Singularity container ──────────────────────────────────────────────────
SIF_FILE="rstudio_${RSTUDIO_VERSION}.sif"
if [[ -f "$SIF_FILE" ]]; then
    echo "✓ Container '$SIF_FILE' already exists — skipping download."
else
    echo "→ Downloading RStudio container (~1 GB, please wait)..."
    singularity pull "docker://rocker/rstudio:${RSTUDIO_VERSION}"
    echo "✓ Container downloaded: $SIF_FILE"
fi

# ── 3. RStudio server config folders ─────────────────────────────────────────
echo "→ Creating RStudio server config files..."
mkdir -p run var-lib-rstudio-server
printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > database.conf
echo "✓ Config files ready."

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Setup complete!"
echo "========================================"
echo ""
echo "  Your username : $USER"
echo "  Your UID      : $UID"
echo ""
echo "  Next step: run   bash rstudio_launch_desktop.sh"
echo ""
