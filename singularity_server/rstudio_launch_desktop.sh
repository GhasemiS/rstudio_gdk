#!/usr/bin/env bash
# =============================================================================
# rstudio_launch_desktop.sh  —  Run this EVERY TIME on desktop.genome.au.dk
# =============================================================================
# Usage:  bash rstudio_launch_desktop.sh
# Must be run from the same folder as rstudio_setup_desktop.sh.
# =============================================================================

set -euo pipefail

# ── Config — edit these to match your project ────────────────────────────────
SLURM_ACCOUNT="NDDgenomics"     # ← your GenomeDK project name
SLURM_CORES=8
SLURM_MEM="128g"
SLURM_TIME="10:00:00"
CONDA_ENV_NAME="rstudio_env"    # ← change if using a different environment
RSTUDIO_VERSION="4.2.2"
# ─────────────────────────────────────────────────────────────────────────────

SIF_FILE="rstudio_${RSTUDIO_VERSION}.sif"
TMUX_SESSION="rstudio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "========================================"
echo "  RStudio Server — Launch"
echo "  (For GenomeDK Desktop)"
echo "========================================"
echo ""

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ ! -f "${SCRIPT_DIR}/${SIF_FILE}" ]]; then
    echo "✗ Error: '${SIF_FILE}' not found in ${SCRIPT_DIR}."
    echo "  Please run rstudio_setup_desktop.sh first."
    exit 1
fi
if [[ ! -f "${SCRIPT_DIR}/database.conf" ]]; then
    echo "✗ Error: database.conf not found."
    echo "  Please run rstudio_setup_desktop.sh first."
    exit 1
fi

# ── Kill any existing session ─────────────────────────────────────────────────
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "→ Existing tmux session '$TMUX_SESSION' found — closing it first..."
    tmux kill-session -t "$TMUX_SESSION"
fi

# ── Clear stale RStudio cache ─────────────────────────────────────────────────
echo "→ Clearing old RStudio cache..."
rm -rf ~/.local/share/rstudio/

echo ""
echo "→ Requesting Slurm interactive job:"
echo "   Account : $SLURM_ACCOUNT"
echo "   Cores   : $SLURM_CORES"
echo "   Memory  : $SLURM_MEM"
echo "   Time    : $SLURM_TIME"
echo ""

# ── Find conda base ───────────────────────────────────────────────────────────
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
    echo "✗ Error: conda installation not found."
    exit 1
fi

# ── Write the inner script to the shared project folder ──────────────────────
# This file is on the shared filesystem so the compute node can read it.
INNER_SCRIPT="${SCRIPT_DIR}/.rstudio_run.sh"

cat > "$INNER_SCRIPT" << INNEREOF
#!/usr/bin/env bash
set -euo pipefail

cd "${SCRIPT_DIR}"

source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV_NAME}"

NODE=\$(hostname)
PORT=\$UID

echo ""
echo "  ✓ Running on node : \$NODE"
echo "  ✓ RStudio port    : \$PORT"
echo "  ✓ User            : \$USER"
echo ""
echo "  Opening Firefox at http://\${NODE}:\${PORT} ..."
echo "  (Keep this terminal open — closing it stops RStudio.)"
echo ""

# Open Firefox after a delay so RStudio has time to start
sleep 8 && firefox "http://\${NODE}:\${PORT}" &

singularity exec \\
  --bind run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf \\
  "${SIF_FILE}" \\
  rserver \\
    --www-port \$UID \\
    --server-user \$USER

echo ""
echo "  RStudio server stopped."
INNEREOF

chmod +x "$INNER_SCRIPT"

# ── Launch tmux → srun → inner script ────────────────────────────────────────
echo "→ Starting tmux session '$TMUX_SESSION'..."
echo ""

tmux new-session -d -s "$TMUX_SESSION" \
    "srun --mem=${SLURM_MEM} --cpus-per-task=${SLURM_CORES} --time=${SLURM_TIME} --account=${SLURM_ACCOUNT} --pty bash '${INNER_SCRIPT}'; echo ''; echo 'Job finished or was cancelled. Press Enter to close.'; read"

echo "  ✓ Slurm job submitted inside tmux session '$TMUX_SESSION'."
echo ""
echo "  Waiting for the compute node to be allocated..."
echo "  (Firefox will open automatically when RStudio is ready.)"
echo ""

# ── Poll tmux until RStudio is up ────────────────────────────────────────────
READY=0
for i in $(seq 1 90); do
    sleep 4
    OUTPUT=$(tmux capture-pane -t "$TMUX_SESSION" -p 2>/dev/null || true)

    if echo "$OUTPUT" | grep -q "RStudio port"; then
        READY=1
        NODE_VAL=$(echo "$OUTPUT" | grep "Running on node" | awk '{print $NF}')
        PORT_VAL=$(echo "$OUTPUT" | grep "RStudio port"    | awk '{print $NF}')
        echo ""
        echo "========================================"
        echo "  RStudio is ready!"
        echo "========================================"
        echo ""
        echo "  Node : $NODE_VAL"
        echo "  Port : $PORT_VAL"
        echo "  URL  : http://${NODE_VAL}:${PORT_VAL}"
        echo ""
        echo "  Firefox should open automatically."
        echo "  If it doesn't, paste the URL above into Firefox manually."
        echo ""
        echo "  To stop: tmux attach -t $TMUX_SESSION  then Ctrl+C"
        echo ""
        break
    fi

    if (( i % 5 == 0 )); then
        echo "  ... still waiting for Slurm allocation (${i}/90) ..."
    fi
done

if [[ $READY -eq 0 ]]; then
    echo ""
    echo "  ⚠ Timed out waiting for the job to start."
    echo "  The job may still be queued. Check with:"
    echo "    tmux attach -t $TMUX_SESSION"
fi
