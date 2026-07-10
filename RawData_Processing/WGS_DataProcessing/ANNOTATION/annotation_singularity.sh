#!/bin/bash
#SBATCH --job-name=anno_singularity
#SBATCH --output=anno_singularity.txt
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8042

sc_pipe=path_to_dlp_software/DLP

srun singularity run --bind path_to_parent_working_folder ${sc_pipe}/ANNOTATION/scp_annotation.sif sh runner.sh
