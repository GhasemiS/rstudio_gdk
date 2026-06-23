# RStudio on GenomeDK Desktop

Scripts to launch RStudio Desktop as a native window on [desktop.genome.au.dk](https://desktop.genome.au.dk), running on a Slurm compute node.

---

## How it works

RStudio runs inside a conda environment on a Slurm compute node. The launch script requests the job inside a tmux session (so it survives accidental terminal closure), activates the environment, and opens RStudio as a desktop window.

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

### A project folder

Put both scripts in a your project folder:
```
/faststorage/project/YOUR_PROJECT/rstudio/
```


---
 
## Download the scripts
 
On the GenomeDK Desktop, open a terminal, go to your shared project folder, and download both scripts with `wget`:
 
```bash
cd /faststorage/project/YOUR_PROJECT/rstudio
wget https://raw.githubusercontent.com/ghasemis/rstudio_gdk/main/rstudio_setup_desktop.sh
wget https://raw.githubusercontent.com/ghasemis/rstudio_gdk/main/rstudio_launch_desktop.sh
```
 
---

## Usage

### Step 1 — Open the GenomeDK Desktop

Go to [desktop.genome.au.dk](https://desktop.genome.au.dk), log in, and open a terminal.

### Step 2 — Go to the folder where you downloaded the files
```bash
cd /faststorage/project/YOUR_PROJECT/rstudio
```

### Step 3 — Set your project name (one time only)

Before running anything, open `rstudio_launch_desktop.sh` in a text editor and change the `SLURM_ACCOUNT` line to your own GenomeDK project name:

```bash
SLURM_ACCOUNT="YOUR_PROJECT"   # ← change this to your project name
```


### Step 4 — Run setup (one time only)

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
SLURM_ACCOUNT="YOUR_PROJECT"   # your GenomeDK project name
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

- If you already have a conda environment with R and Rstudio, set `CONDA_ENV_NAME` to its name in `rstudio_launch_desktop.sh` and skip the setup script.
- For reproducible package management within R projects, use `renv`. It is included in the environment.
- For datasets over 200k cells you should rise SLURM_MEM to 256g
