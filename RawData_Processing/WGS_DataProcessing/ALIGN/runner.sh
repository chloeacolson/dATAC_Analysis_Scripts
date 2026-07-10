#!/bin/bash
#SBATCH --job-name=align_singularity_runner
#SBATCH --output=align_singularity_runner.txt
#SBATCH --partition=compute
#SBATCH --time=120:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem-per-cpu=8042



single_cell alignment --input_yaml align_inputs.yaml \
--maxjobs 48 --sentinel_only \
--submit local --loglevel DEBUG \
--tmpdir temp --pipelinedir pipeline \
--output_prefix output --bams_dir bams \
--config_file config_highmem.yaml \
--sequencing_center TPU \
--library_id Sample
