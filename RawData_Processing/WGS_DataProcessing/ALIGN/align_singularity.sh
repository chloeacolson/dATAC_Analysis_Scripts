#!/bin/bash
#SBATCH --job-name=align_singularity
#SBATCH --output=align_singularity_%J.txt
#SBATCH --partition=compute
#SBATCH --time=120:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem-per-cpu=8042


export SINGULARITY_CACHEDIR=$PWD/singularity_cache
export SINGULARITY_TMPDIR=$PWD/singularity_tmp

sc_pipe=path_to_dlp_software/DLP

srun singularity run --bind path_to_working_parent_folder /${sc_pipe}/ALIGN/scp_alignment_v0.8.26.sif sh runner.sh
