#!/bin/bash
#SBATCH --job-name=hmm_singularity
#SBATCH --output=hmm_singularity.txt
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem-per-cpu=8042


sc_pipe=path_to_dlp_software/DLP

srun singularity run --bind path_to_parent_working_folder ${sc_pipe}/HMMCOPY/scp_hmmcopy.sif sh runner.sh

