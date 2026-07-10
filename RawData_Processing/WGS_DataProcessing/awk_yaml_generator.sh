#!/bin/sh

filelist="ExampleSourceTable.txt"


#### create align_inputs.yaml file for ALIGN module of the DLP single cell pipeline

awk -v OFS='\n' 'NR != 1  \
{print $12":", \
"  column: 1", \
"  condition: " $11, \
"  fastqs:", \
"    flowcell_1:", \
"      fastq_1: " $7, \
"      fastq_2: " $8, \
"      sequencing_center: TPU", \
"      trim: true", \
"  img_col: 45", \
"  index_i5: i5-" $2, \
"  index_i7: i7-" $4, \
"  library_id: " $11, \
"  pick_met: " $14, \
"  primer_i5: " $1, \
"  primer_i7: " $3, \
"  row: 20", \
"  is_control: FALSE", \
"  sample_id: " $12}' \
"$filelist" > align_inputs.yaml

#### after running ALIGN, create hmm_inputs.yaml file for HMMCOPY module of DLP single cell pipeline
# input the path to align

awk -v OFS='\n' 'NR != 1  \
{print $12":", \
"  bam: path_to_align/ALIGN/bams/" $12 ".bam", \
"  column: 1", \
"  condition: " $11, \
"  img_col: 45", \
"  index_i5: i5-" $2, \
"  index_i7: i7-" $4, \
"  pick_met: " $14, \
"  primer_i5: " $1, \
"  primer_i7: " $3, \
"  row: 20", \
"  is_control: FALSE", \
"  sample_id: " $12, \
"  library_id: " $11}' \
"$filelist" > hmm_inputs.yaml

#### after running ALIGN + HMMCOPY, create hmm_inputs_1M.yaml file for DLP single cell pipeline - this filters for cells with sufficient reads

awk -v OFS='\n' 'NR != 1  {if($9 >= 1000000) \
{print $12":", \
"  bam: path_to_align/ALIGN/bams/" $12 ".bam", \
"  column: 1", \
"  condition: " $11, \
"  img_col: 45", \
"  index_i5: i5-" $2, \
"  index_i7: i7-" $4, \
"  pick_met: " $14, \
"  primer_i5: " $1, \
"  primer_i7: " $3, \
"  row: 20", \
"  is_control: FALSE", \
"  sample_id: " $12, \
"  library_id: " $11}}' \
"$filelist" > hmm_inputs1M.yaml