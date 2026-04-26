#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32

bfile_prefix="STEP1_FILESET"
outfile_prefix="STEP3_FILESET"
prune_file="STEP2_FILESET.prune.in"
threads="28"

module load plink/1.90

plink --bfile ${bfile_prefix} --double-id --allow-extra-chr --mind 0.99 --threads ${threads} --extract ${prune_file} --make-bed --out ${outfile_prefix} 
