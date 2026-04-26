#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32

bfile_prefix="STEP1_FILESET"
outfile_prefix="STEP2_FILESET"
threads="28"

module load plink/1.90

plink --bfile ${bfile_prefix} --double-id --allow-extra-chr --mind 0.99 --threads ${threads} --indep-pairwise 50 10 0.2 --out ${outfile_prefix}
