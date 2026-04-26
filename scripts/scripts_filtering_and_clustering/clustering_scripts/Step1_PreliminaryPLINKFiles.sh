#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32

path_to_vcf="/scratch/bioconsult/zakas_project/SNV_Calls_Filtered/snps.pass.lowqualfiltered_passed_lowdepthfiltered_passed.vcf.gz"
outfile_prefix="STEP1_FILESET"
threads="28"

module load plink/1.90

#NOTE: --double-id prevents "_" from being treated like a delimiter (underscores are used in sample IDs)
#--allow-extra-chr allows for non-standard chromosome IDs to be tolerated (our chromosome IDs start with "Ch" thus rendering them non-standard)
#--mind 1 instructs plink to ignore any sample with 100% missing genotype data (this is specfically to filter out Bar_L_14)
#--set-missing-var-ids handles a formating problem

plink --vcf ${path_to_vcf} --double-id --allow-extra-chr --mind 0.99 --threads ${threads} --set-missing-var-ids @:# --make-bed --out ${outfile_prefix}
