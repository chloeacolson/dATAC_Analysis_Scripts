#!/bin/bash
#SBATCH --job-name=anno_singularity_runner
#SBATCH --output=anno_singularity_runner.txt
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8042


export NUMEXPR_MAX_THREADS=1
 
 single_cell annotation \
 --input_yaml annotation_inputs.yaml \
 --maxjobs 8 --nocleanup \
 --sentinel_only --submit local --loglevel DEBUG \
 --tmpdir temp --pipelinedir pipeline --out_dir output \
 --config_override '{"refdir": "path_to_refdata/refdata"}' \
 --library_id Sample