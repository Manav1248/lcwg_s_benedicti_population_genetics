#!/bin/bash

#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32

infile_prefix="STEP3_FILESET"
outfile_prefix="STEP4_FILESET"
threads="28"

module load plink/1.90
plink --bfile ${infile_prefix} --allow-extra-chr --threads ${threads} --pca --out ${outfile_prefix}
