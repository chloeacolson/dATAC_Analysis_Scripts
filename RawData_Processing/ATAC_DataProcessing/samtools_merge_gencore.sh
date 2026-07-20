#!/bin/bash
#SBATCH --job-name=samtools_merge
#SBATCH --output=logs/samtools_merge_%J.txt
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=8000


##############################################################################
# load necessary tools and packages
srun hostname

module load anaconda

conda init
conda activate dataprocessing

module load java/1.8.0_261
module load SAMtools


ulimit -u
ulimit -n 100000
ulimit -u


echo " "
echo "########################################################################################"
echo "merge deduplicated bams into one single pseudo-bulk bam for further analysis"
echo "########################################################################################"
echo " "

# Input the path to the bams obtained via fastq_pool_demux_barcoding_bowtie2.sh

cd path_to_bams

mkdir merged


# Merge consensus bams that have the tn5 barcodes used for your sample,e.g,
samtools merge -f merged/Sample_DATAC_sn_consensus_merged.bam Sample_DATAC_*TCGATATC.sort_consensus.bam 

# Compute basic metrics for the merged bam
# Input path to picard-tools

java -Xmx4g -Djava.io.tmpdir=/tmp -XX:-UseCompressedClassPointers -jar \
path_to_picard_tools/picard-tools/2.23.8/picard.jar CollectInsertSizeMetrics \
I=merged/Sample_DATAC_sn_consensus_merged.bam \
O=merged/Sample_DATAC_sn_consensus_merged.insert_metrics \
H=merged/Sample_DATAC_sn_consensus_merged.insert_hist.pdf

msg="finished"; echo "-- $msg $longLine"; >&2 echo "-- $msg $longLine"



