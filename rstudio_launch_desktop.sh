#!/usr/bin/env bash
# =============================================================================
# rstudio_launch_desktop.sh  —  Run this EVERY TIME on desktop.genome.au.dk
# =============================================================================
# Usage:  bash rstudio_launch_desktop.sh
# Must be run from the same folder as rstudio_setup_desktop.sh.
#
# What it does:
#   1. Opens a tmux session (survives accidental terminal close)
#   2. Requests an interactive Slurm job (10 h, 128 GB, 8 cores)
#   3. Activates conda and opens RStudio Desktop as a native window
# =============================================================================

set -euo pipefail

# ── Config — edit these to match your project ────────────────────────────────
SLURM_ACCOUNT="NDDgenomics"     # ← your GenomeDK project name
SLURM_CORES=8
SLURM_MEM="128g"
SLURM_TIME="10:00:00"
CONDA_ENV_NAME="rstudio_env"    # ← must match name in rstudio_setup_desktop.sh
# ─────────────────────────────────────────────────────────────────────────────

TMUX_SESSION="rstudio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "========================================"
echo "  RStudio — Launch"
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
    echo "✗ Error: conda not found. Please run rstudio_setup_desktop.sh first."
    exit 1
fi

# ── Kill any leftover tmux session ───────────────────────────────────────────
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "→ Existing tmux session '$TMUX_SESSION' found — closing it first..."
    tmux kill-session -t "$TMUX_SESSION"
fi

echo "→ Requesting Slurm interactive job:"
echo "   Account : $SLURM_ACCOUNT"
echo "   Cores   : $SLURM_CORES"
echo "   Memory  : $SLURM_MEM"
echo "   Time    : $SLURM_TIME"
echo ""

# ── Write inner script to shared folder (readable from compute node) ─────────
INNER_SCRIPT="${SCRIPT_DIR}/.rstudio_run.sh"

cat > "$INNER_SCRIPT" << INNEREOF
#!/usr/bin/env bash
set -euo pipefail

source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_NAME}"

echo ""
echo "  ✓ Running on node : \$(hostname)"
echo "  ✓ User            : \$USER"
echo "  ✓ Conda env       : ${CONDA_ENV_NAME}"
echo ""
echo "  Starting RStudio Desktop..."
echo "  (Close the RStudio window or press Ctrl+C here to stop.)"
echo ""

rstudio

echo ""
echo "  RStudio closed."
INNEREOF

chmod +x "$INNER_SCRIPT"

# ── Launch: tmux → srun → inner script ───────────────────────────────────────
echo "→ Starting tmux session '$TMUX_SESSION'..."

tmux new-session -d -s "$TMUX_SESSION" \
    "srun --mem=${SLURM_MEM} --cpus-per-task=${SLURM_CORES} --time=${SLURM_TIME} --account=${SLURM_ACCOUNT} --pty bash '${INNER_SCRIPT}'; echo ''; echo 'Job finished or was cancelled. Press Enter to close.'; read"

echo "  ✓ Slurm job submitted — waiting for compute node..."
echo ""

# ── Poll until RStudio is reported as starting ────────────────────────────────
for i in $(seq 1 60); do
    sleep 4
    OUTPUT=$(tmux capture-pane -t "$TMUX_SESSION" -p 2>/dev/null || true)

    if echo "$OUTPUT" | grep -q "Starting RStudio"; then
        echo "  ✓ RStudio is launching — the window should appear shortly."
        echo ""
        echo "  To stop: close the RStudio window, or:"
        echo "    tmux attach -t $TMUX_SESSION  then Ctrl+C"
        echo ""
        exit 0
    fi

    if (( i % 5 == 0 )); then
        echo "  ... still waiting for Slurm allocation (${i}/60) ..."
    fi
done

echo ""
echo "  ⚠ Timed out waiting. The job may still be queued."
echo "  Check with:  tmux attach -t $TMUX_SESSION"
