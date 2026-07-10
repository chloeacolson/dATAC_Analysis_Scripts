#!/bin/bash
#SBATCH --job-name=hmm_singularity_runner
#SBATCH --output=hmm_singularity_runner.txt
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=48
#SBATCH --mem-per-cpu=8042


 single_cell hmmcopy \
 --input_yaml hmm_inputs.yaml \
 --maxjobs 48 \
 --sentinel_only --submit local --loglevel DEBUG \
 --tmpdir temp --pipelinedir pipeline_allcells --out_dir output_allcells \
 --config_file config_highmem.yaml \
 --library_id Sample
 
