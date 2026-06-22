#!/usr/bin/env bash
# =============================================================================
# rstudio_setup_desktop.sh  —  Run this ONCE per user on desktop.genome.au.dk
# =============================================================================
# Usage:  bash rstudio_setup_desktop.sh
# Place this in your shared project rstudio/ folder, e.g.:
#   /faststorage/project/YOUR_PROJECT/rstudio/
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
CONDA_ENV_NAME="rstudio_env"
R_VERSION="4.4.2"
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "========================================"
echo "  RStudio — One-time Setup"
echo "  (GenomeDK Desktop)"
echo "========================================"
echo ""

# ── Find conda ────────────────────────────────────────────────────────────────
CONDA_BASE=""
for candidate in \
        "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3" \
        "/opt/conda" "/usr/local/conda"; do
    if [[ -f "$candidate/etc/profile.d/conda.sh" ]]; then
        CONDA_BASE="$candidate"; break
    fi
done
if [[ -z "$CONDA_BASE" ]] && command -v conda &>/dev/null; then
    CONDA_BASE="$(conda info --base 2>/dev/null || true)"
fi
if [[ -z "$CONDA_BASE" ]]; then
    echo "✗ Error: conda not found."
    echo "  Install Miniconda from https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi
source "$CONDA_BASE/etc/profile.d/conda.sh"
echo "✓ Conda found at: $CONDA_BASE"

# ── Create conda environment ──────────────────────────────────────────────────
if conda env list | awk '{print $1}' | grep -qx "$CONDA_ENV_NAME"; then
    echo "✓ Conda environment '$CONDA_ENV_NAME' already exists — skipping."
else
    echo "→ Creating conda environment with R $R_VERSION, RStudio, tidyverse..."
    echo "  (This takes a few minutes)"
    conda create -y -n "$CONDA_ENV_NAME" \
        -c conda-forge \
        r-base=$R_VERSION \
        rstudio-desktop \
        r-tidyverse \
        r-ggplot2 \
        r-renv
    echo "✓ Environment '$CONDA_ENV_NAME' created."
fi

echo ""
echo "========================================"
echo "  Setup complete!"
echo "========================================"
echo ""
echo "  Next step: run   bash rstudio_launch_desktop.sh"
echo ""
