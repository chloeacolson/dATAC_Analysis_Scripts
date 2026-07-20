#!/bin/bash
#SBATCH --job-name=fastq_pool_demux
#SBATCH --output=logs/fastq_pool_demux_%J.txt
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=8000
#SBATCH --array=1-2304 #number of cells in sample


##############################################################################
# load necessary tools and packages
srun hostname

#unset DISPLAY

module load anaconda

conda init
conda activate dataprocessing # this conda environment contains ultraplex 

module load java/1.8.0_261
module load SAMtools


##############################################################################
# setup folders and samples

# sourcetable - see Example Source Table
filelist="path_to_sourcetable"

# retrieve fastq paths
fastq1=$(awk -v var="$SLURM_ARRAY_TASK_ID" 'NR ==var { OFS="\t";print $7}' $filelist)
fastq2=$(awk -v var="$SLURM_ARRAY_TASK_ID" 'NR ==var { OFS="\t";print $8}' $filelist)

#poolname in this run is the samplename
poolname=$(awk -v var="$SLURM_ARRAY_TASK_ID" 'NR ==var { OFS="\t";print $6}' $filelist)

# set the library name (e.g. cell line + time point)
library="lib_name"

index_barcode=$(awk -v var="$SLURM_ARRAY_TASK_ID" 'NR ==var { OFS="\t";print $5}' $filelist)

# Define the parent directory which will hold the filtered fastqs and the aligned bams
fastq_dir="path to desired fastq dir"

# Define the directory in which you want only the filtered fastqs to go
OUT_dir=demultiplexed_pools

# create all necessary directories in fastq_dir
cd ${fastq_dir}
mkdir ${OUT_dir}
mkdir ${OUT_dir}/${poolname}
mkdir bam

##### EXTREMELY IMPORTANT to set up individual folders for each sample pool. If all array jobs read/write into the same folder there will be collision between jobs!!

tmp_dir=${OUT_dir}/${poolname}

# Information about the sample/cell being demultiplexed
echo " "
echo "########################################################################################"
echo "demultiplex by 5-prime inline barcode and attach cell barcode to start of read header - sample: "${poolname}
echo "index_barcode: "${index_barcode}
echo "########################################################################################"
echo " "

### treat R2 as FWD read because it carries the 5-prime inline Tn5 barcode; __main__.py of ULTRAPLEX has been modified so that it will NOT remove spaces in read names. This ensures that read pairs will have identical names up to the first space - if they are not identical, BWA refuses to work
## -q 0: prevents ultraplex from 5' trimming 
ultraplex -t 2 -i ${fastq2} \
-i2 ${fastq1} \
-q 0 \
-b path/ultraplex_Tn5_barcodes_noUMI.csv \
-d ${tmp_dir} \
--fiveprimemismatches 1 \
--outputprefix ${poolname} \
--adapter CTGTCTCTTATACACATCTGACGCTGCCGACGA \
--adapter2 CTGTCTCTTATACACATCT


### Tn5 inline barcodes --> loop and map/dedup single cell fastqs


# map ATAC reads: the barcodes listed below should correspond to the tn5 indexes you used to label open chromatin in this sample/set of cells, e.g.,

barcode=('TCGATATC')

for ((i=0;i<${#barcode[@]};i++))
do

minimumsize=10000 # impose a minimum size on the fastq
actualsize=$(wc -c <"${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd.fastq.gz")
echo "sample: "${poolname}"_"${barcode[i]} " ---- Actual filesize: " $actualsize


if [ $actualsize -ge $minimumsize ]; then

# print out info about the cell + barcode and define key variables for functions run below
echo "inline_barcode: " ${barcode[i]}

cell_barcode="${poolname}_${barcode[i]}"

readgroup="@RG\tID:${poolname}_${cell_barcode}\tLB:${library}\tSM:${poolname}_${cell_barcode}\tPL:ILLUMINA"

inputfile="${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd.fastq.gz"

echo "input file: " ${inputfile}

# trim off barcodes and Tn5 adapter sequence; 
# add cell_barcode to left side of read name; 
# trim to maximum 50nt for optimal ATAC read mapping (here it is set to 35)
# input path_to_seqtk

path_to_seqtk/seqtk trimfq -b 20 -L 35 \
${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd.fastq.gz \
| sed "s/^@LH00409/@${cell_barcode}:LH00409/"| gzip > ${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd_trim.fastq.gz 

path_to_seqtk/seqtk trimfq -L 35 \
${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Rev.fastq.gz \
| sed "s/^@LH00409/@${cell_barcode}:LH00409/" | gzip > ${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_BCfix_Rev.fastq.gz


echo "number of lines in ultraplex_${poolname}_${barcode[i]}_Fwd.fastq.gz"
zcat ${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd.fastq.gz | wc -l

echo "number of lines in ultraplex_${poolname}_${barcode[i]}_Fwd_trim.fastq.gz"
zcat ${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd_trim.fastq.gz | wc -l

###map reads and add "CB:Z" style cell barcode to end of the line, this ensures compatibility with downstream applications requiring CB tag for unique single cell/nucleus identificiation (ie ArchR)


conda activate bowtie2.4.2
module load java/1.8.0_261
module load SAMtools


echo " "
echo "########################################################################################"
echo "#### mapping with Bowtie2"
echo "########################################################################################"
echo " "
# input path_to_genome_assembly

bowtie2 -p 2 --local --very-sensitive -X 1000 -k 5 --no-mixed --no-discordant \
--rg-id ${poolname}_${cell_barcode} --rg SM:${poolname}_${cell_barcode} --rg LB:${library} --rg PU:${library} --rg PL:ILLUMINA \
-x path_to_genome_assembly/gencode_genome_PRI_GRCh38.p13_v41/GRCh38.p13_v41.primary_assembly \
-2 ${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_Fwd_trim.fastq.gz \
-1 ${tmp_dir}/ultraplex_${poolname}_${barcode[i]}_BCfix_Rev.fastq.gz | \
samtools view -@ 2 -h | awk -v barcode="$cell_barcode" '/^@/ {print;next} {print $0 "\tCB:Z:" barcode}' | samtools view -Shb -q 1 -@ 2 -> ${tmp_dir}/${poolname}_${barcode[i]}.unsort.bam

echo " "
echo "########################################################################################"
echo "#### sort and index bam"
echo "########################################################################################"
echo " "

samtools sort -@ 2 ${tmp_dir}/${poolname}_${barcode[i]}.unsort.bam -o ${tmp_dir}/${poolname}_${barcode[i]}.sort.bam
samtools index -@ 2 ${tmp_dir}/${poolname}_${barcode[i]}.sort.bam


conda activate dataprocessing
module load java/1.8.0_261

echo " "
echo "########################################################################################"
echo "#### GENCORE deduplicate/consensus bam"
echo "########################################################################################"
echo " "
# Gencore creates consensus reads from reads assigned to the same DNA region, i.e., reduces errors in the obtained sequences
# input path_to_gencore
# input path_to_genome_assembly

path_to_gencore/gencore \
--in ${tmp_dir}/${poolname}_${barcode[i]}.sort.bam \
--out bam/${poolname}_${barcode[i]}.sort_consensus_SR2.bam \
--ref path_to_genome_assembly/gencode_genome_PRI_GRCh38.p13_v41/GRCh38.p13_v41.primary_assembly.genome.fa \
--supporting_reads 1 \
--json bam/${poolname}_${barcode[i]}.sort_consensus.json \
--html bam/${poolname}_${barcode[i]}.sort_consensus.html

# input path_to_picard-tools

java -Xmx4g -Djava.io.tmpdir=/tmp -XX:-UseCompressedClassPointers -jar path_to_picard-tools/picard-tools/2.23.8/picard.jar MarkDuplicates \
--INPUT ${tmp_dir}/${poolname}_${barcode[i]}.sort.bam \
--OUTPUT bam/${poolname}_${barcode[i]}.sort_dedup.bam \
--METRICS_FILE bam/${poolname}_${barcode[i]}.sort_dedup.metrics \
--REMOVE_DUPLICATES true \
--CREATE_INDEX true

java -Xmx4g -Djava.io.tmpdir=/tmp -XX:-UseCompressedClassPointers -jar path_to_picard-tools/picard-tools/2.23.8/picard.jar CollectInsertSizeMetrics \
I=bam/${poolname}_${barcode[i]}.sort_consensus_SR2.bam \
O=bam/${poolname}_${barcode[i]}.sort_consensus_SR2.insert_metrics \
H=bam/${poolname}_${barcode[i]}.sort_consensus_SR2.insert_hist.pdf

java -Xmx4g -Djava.io.tmpdir=/tmp -XX:-UseCompressedClassPointers -jar path_to_picard-tools/picard-tools/2.23.8/picard.jar CollectInsertSizeMetrics \
I=bam/${poolname}_${barcode[i]}.sort_consensus.bam \
O=bam/${poolname}_${barcode[i]}.sort_consensus.insert_metrics \
H=bam/${poolname}_${barcode[i]}.sort_consensus.insert_hist.pdf


else
	echo "Filesize too small, skipping file process"

fi

done

msg="finished"; echo "-- $msg $longLine"; >&2 echo "-- $msg $longLine"

