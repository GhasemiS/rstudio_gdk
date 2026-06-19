# RStudio Server on GenomeDK

Scripts to launch RStudio Server on the [GenomeDK HPC cluster](https://genome.au.dk) via a Singularity container, with no X11 forwarding and no manual tunnelling — just a browser tab.

Designed for lab members who are not command-line experts. Two scripts, and RStudio opens in Firefox automatically.

---

## How it works

RStudio runs inside a Singularity container on a Slurm compute node. Because we use the **GenomeDK Desktop** (`desktop.genome.au.dk`) rather than a plain SSH session, you already have a browser and a display — so there is no need to set up an SSH tunnel. The launch script requests the compute job, starts the server, and opens Firefox for you.

---

## Prerequisites

These must be in place before running the scripts. On GenomeDK most of these are already available — check each one first.

### 1. Conda (Miniconda or Anaconda)

The scripts need conda to create and activate an R environment.

Check if you have it:
```bash
conda --version
```

If not, install Miniconda in your home directory:
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```
Follow the prompts and say **yes** to initialising conda. Then close and reopen your terminal.

### 2. Singularity

Used to run the RStudio container. Singularity is already installed as a module on GenomeDK. Load it once per session or add it to your `~/.bashrc`:

```bash
module load singularity
```

To make it permanent so it loads every login:
```bash
echo "module load singularity" >> ~/.bashrc
```

### 3. tmux

Used to keep the RStudio session alive even if the terminal window is accidentally closed. tmux is pre-installed on GenomeDK — no action needed.

### 4. A shared project folder on GenomeDK

The scripts and the downloaded container (~1 GB) should live in a shared project folder so any lab member can use them without each person downloading the container separately. For example:

```
/faststorage/project/YOUR_PROJECT/rstudio/
```

Put both scripts there and run them from that folder.

---

## Files

| File | Run where | Run when |
|---|---|---|
| `rstudio_setup_desktop.sh` | GenomeDK Desktop terminal | **Once** per user |
| `rstudio_launch_desktop.sh` | GenomeDK Desktop terminal | Every time you want RStudio |

---

## Usage

### Step 1 — Open the GenomeDK Desktop

Go to [desktop.genome.au.dk](https://desktop.genome.au.dk) in your browser and log in. Open a terminal.

### Step 2 — Go to the shared scripts folder

```bash
cd /faststorage/project/YOUR_PROJECT/rstudio
```

### Step 3 — Run setup (first time only)

```bash
bash rstudio_setup_desktop.sh
```

This will:
- Find your conda installation
- Create the `ABC9rstudio` conda environment with R 4.4.2, tidyverse, ggplot2, and renv
- Download the RStudio Singularity container (~1 GB — takes a few minutes)
- Create the config files RStudio Server needs

It is safe to re-run — it skips anything already done.

### Step 4 — Launch RStudio

```bash
bash rstudio_launch_desktop.sh
```

This will:
- Start a tmux session so the job survives accidental terminal closure
- Request a Slurm interactive job (10 hours, 128 GB RAM, 8 cores)
- Activate conda and start RStudio Server inside the Singularity container
- Open Firefox automatically at the correct address

Wait about 30–60 seconds for the job to be allocated and RStudio to start. Firefox will open on its own. If it doesn't, the terminal will print the URL — paste it into Firefox manually.

---

## Stopping RStudio

1. Close the RStudio browser tab.
2. Attach to the tmux session and press `Ctrl+C`:
   ```bash
   tmux attach -t rstudio
   ```
3. The Slurm job will end and resources will be released.

---

## Customising resources

Open `rstudio_launch_desktop.sh` in a text editor and change the values at the top:

```bash
SLURM_ACCOUNT="NDDgenomics"   # your GenomeDK project name
SLURM_CORES=8                 # number of CPU cores
SLURM_MEM="128g"              # RAM
SLURM_TIME="10:00:00"         # wall time (hh:mm:ss)
CONDA_ENV_NAME="ABC9rstudio"  # conda environment to activate
```

If you already have your own conda environment with R, set `CONDA_ENV_NAME` to its name instead.

---

## Using your own R packages / renv

RStudio will start in the directory where the script lives. To use a project-specific `renv` lockfile, either:
- Move your R project into the same folder, or
- Set the working directory inside RStudio after it opens (`Session → Set Working Directory`)

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `conda: command not found` | Install Miniconda (see Prerequisites) and reopen the terminal |
| `singularity: command not found` | Run `module load singularity` or add it to `~/.bashrc` |
| Firefox opens to the AlmaLinux welcome page, not RStudio | RStudio may still be starting — wait 30 s then navigate to `http://<node>:<UID>` shown in the terminal |
| `sif file not found` | Make sure you `cd` into the `rstudio/` folder before running the script |
| Slurm job pending for a long time | The cluster is busy — the job will start when resources are free. Attach to the tmux session to watch: `tmux attach -t rstudio` |
| Want to check if RStudio is running | `tmux attach -t rstudio` — you will see the server log output |
| Forgot the URL | Run `echo $UID` in any terminal on GenomeDK to get your port. The node name is shown in the tmux session. |
| Want a longer or shorter session | Change `SLURM_TIME` in `rstudio_launch_desktop.sh` |

---

## Background

RStudio is deployed via the [rocker/rstudio](https://rocker-project.org) Docker image, pulled and run as a Singularity container. This avoids the display incompatibilities of X11-forwarded RStudio Desktop and the dependency conflicts of conda-installed RStudio. The conda environment provides the R installation and packages that RStudio Server uses; Singularity provides the server process itself.

The R environment (`ABC9rstudio`) is defined in a `.yml` file maintained at [AU-ABC/AU-ABC.github.io](https://github.com/AU-ABC/AU-ABC.github.io) and includes:
- R 4.4.2
- tidyverse
- ggplot2
- renv
