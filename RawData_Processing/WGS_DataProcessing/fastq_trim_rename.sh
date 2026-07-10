#!/bin/bash
#SBATCH --job-name=fastq_trim
#SBATCH --output=logs/fastq_trim_%J.txt
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8000
#SBATCH --array=3-769 # Number of cells


##############################################################################
# load necessary tools and packages
srun hostname


unset DISPLAY

# module load anaconda
# source /opt/software/applications/anaconda/3/etc/profile.d/conda.sh
# 
# conda init
# conda activate dataprocessing

# module load java/1.8.0_261
# module load SAMtools
# 

##############################################################################
# setup folders and samples

filelist="path to source table"


poolname=$(awk -v var="$SLURM_ARRAY_TASK_ID" 'NR ==var { OFS="\t";print $6}' $filelist)
#poolname in this run is the samplename
index_barcode=$(awk -v var="$SLURM_ARRAY_TASK_ID" 'NR ==var { OFS="\t";print $5}' $filelist)

# original fastq folder
fastq_dir="path to untrimmed fastqs"

# new (destination fastq folder)
fastq_dir_out="path to trimmed fastq destination"

cd ${fastq_dir_out}
mkdir ${poolname}

cd ${fastq_dir}


echo " "
echo "########################################################################################"
echo "trim 28bp from Read2 and rename Read1 - sample: "${poolname}
echo "index_barcode: "${index_barcode}
echo "########################################################################################"
echo " "




###trim off barcodes and Tn5 adapter sequence

path_to_seqtk/seqtk trimfq -b 28 \
${fastq_dir}/*/${poolname}_2.fq.gz \
| gzip > ${fastq_dir_out}/${poolname}/${poolname}_2_trim.fq.gz

# Move the trimmed R2 fastq out of its sample name folder
mv ${fastq_dir_out}/${poolname}/${poolname}_2_trim.fq.gz ${fastq_dir_out}/${poolname}_2_trim.fq.gz

# Copy the R1 fastq from the original folder to new folder (if they're different...)
cp ${fastq_dir}/*/${poolname}_1.fq.gz ${fastq_dir_out}/${poolname}_1.fq.gz 



msg="finished"; echo "-- $msg $longLine"; >&2 echo "-- $msg $longLine"

