# RStudio on GenomeDK Desktop

Scripts to launch RStudio Desktop as a native window on [desktop.genome.au.dk](https://desktop.genome.au.dk), running on a Slurm compute node. No browser, no tunnels, no containers — just RStudio.

---

## How it works

RStudio runs inside a conda environment on a Slurm compute node. The launch script requests the job inside a tmux session (so it survives accidental terminal closure), activates the environment, and opens RStudio as a normal desktop window.

---

## Files

| File | Run when |
|---|---|
| `rstudio_setup_desktop.sh` | **Once** per user — creates the conda environment |
| `rstudio_launch_desktop.sh` | Every time you want RStudio |

---

## Prerequisites

### Conda (Miniconda or Anaconda)

Check if you have it:
```bash
conda --version
```

If not, install Miniconda:
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```
Say **yes** to initialising conda, then close and reopen your terminal.

### tmux

Pre-installed on GenomeDK — nothing to do.

### A shared project folder

Put both scripts in a shared folder so all lab members can use them:
```
/faststorage/project/YOUR_PROJECT/rstudio/
```

---

## Usage

### Step 1 — Open the GenomeDK Desktop

Go to [desktop.genome.au.dk](https://desktop.genome.au.dk), log in, and open a terminal.

### Step 2 — Go to the shared scripts folder

```bash
cd /faststorage/project/YOUR_PROJECT/rstudio
```

### Step 3 — Set your project name

Before running anything, open `rstudio_launch_desktop.sh` in a text editor and change the `SLURM_ACCOUNT` line to your own GenomeDK project name:

```bash
SLURM_ACCOUNT="NDDgenomics"   # ← change this to your project name
```

You can find your project name by running `ls /faststorage/project/` on GenomeDK.

### Step 4 — Run setup (first time only)

```bash
bash rstudio_setup_desktop.sh
```

This creates a conda environment called `rstudio_env` with:
- R 4.4.2
- RStudio Desktop
- tidyverse, ggplot2, renv

Takes a few minutes. Safe to re-run — skips steps already done.

### Step 5 — Launch RStudio

```bash
bash rstudio_launch_desktop.sh
```

This will:
- Start a tmux session
- Request a Slurm job (10 hours, 128 GB RAM, 8 cores)
- Activate the conda environment
- Open RStudio as a normal desktop window

RStudio will appear as a window on the GenomeDK desktop once the job is allocated (usually within a minute).

---

## Stopping RStudio

Close the RStudio window normally, or attach to the tmux session and press `Ctrl+C`:
```bash
tmux attach -t rstudio
```

---

## Customising resources

Edit the top section of `rstudio_launch_desktop.sh`:

```bash
SLURM_ACCOUNT="NDDgenomics"   # your GenomeDK project name
SLURM_CORES=8                 # CPU cores
SLURM_MEM="128g"              # RAM
SLURM_TIME="10:00:00"         # wall time (hh:mm:ss)
CONDA_ENV_NAME="rstudio_env"  # conda environment name
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `conda: command not found` | Install Miniconda (see Prerequisites) and reopen the terminal |
| RStudio window doesn't appear | The job may still be queued — run `tmux attach -t rstudio` to watch progress |
| RStudio crashes on startup | Try `conda update -n rstudio_env rstudio-desktop` to get the latest version |
| Job runs but RStudio won't open | Make sure you are on the **desktop** (`desktop.genome.au.dk`) not a plain SSH session — a display is required |
| Want to check what's running | `tmux attach -t rstudio` shows the live log |
| Want a longer session | Change `SLURM_TIME` in `rstudio_launch_desktop.sh` |

---

## Notes

- The conda environment is created in your home directory (`~/.conda/envs/rstudio_env`) and is personal to each user, but the scripts themselves are shared.
- If you already have a conda environment with R, set `CONDA_ENV_NAME` to its name in `rstudio_launch_desktop.sh` and skip the setup script.
- For reproducible package management within R projects, use `renv` — it is included in the environment.
