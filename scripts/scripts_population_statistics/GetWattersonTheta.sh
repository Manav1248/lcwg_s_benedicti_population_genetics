#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24

#Conda environment pixy_env must be acviated for this script!!!

path_to_vcf="/scratch/bioconsult/zakas_project/all_samples.allsites.vcf.gz"
path_to_dirs="/scratch/bioconsult/zakas_project/trimmed_reads_unzipped/gatk_downstream"
window_size="10000" #This specific method of pixy execution does not consider entire chromosome scaffolds but windows; the window size can be specified here
threads="20"
outdir="/scratch/bioconsult/zakas_project/PopStats_Final_Unfiltered/PopStats_WattersonTheta"

echo GENERATING POPULATIONS COMPANION FILE
for pathway in ${path_to_dirs}/*; do
        dir_name=$(basename $pathway)

        #Below: only loop through specific directory if it has population data
        if [[ "$dir_name" != "qc_reports" && "$dir_name" != "reference" && "$dir_name" != "out" && "$dir_name" != "err" ]]; then

                #Below: within the directory, loop through bam files to add pathways to the file to be used for variant calling
                for bamfile in ${pathway}/*.bam; do
                        if [[ $bamfile != "/scratch/bioconsult/zakas_project/trimmed_reads_unzipped/gatk_downstream/Bar_L/Bar_L_F14.sorted.dedup.bam" ]]; then #ignore truncaed BAM
				individual=$(basename $bamfile .bam)
				individual=$(echo $individual | cut -d '.' -f 1)
				population=$(basename $pathway)
				echo -e "${individual}\t${population}" >> populations.txt
                        fi

                done
        fi
done

echo GETTING Watterson Theta VALUES
pixy --stats watterson_theta --window_size ${window_size} --vcf ${path_to_vcf} --populations populations.txt --n_cores ${threads} --output_folder ${outdir}
