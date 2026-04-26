#!/bin/bash

path_to_vcf="/scratch/bioconsult/zakas_project/SNV_Calls_Filtered/snps.pass.lowqualfiltered_passed.vcf.gz"
path_to_reference="/scratch/bioconsult/zakas_project/gatk_downstream/reference/Sbenedicti_v2.fasta"
outfile="snps.pass.lowqualfiltered_passed_lowdepthfiltered.vcf.gz"

echo FILTERING THE ALREADY FILTERED SNP VCF FOR LOW DEPTH SITES
echo NOTE THAT THIS ONLY CHANGES THE PASS FLAG, ANOTHER SCRIPT WILL DO THE ACTUAL FILTERING

module load gatk/4.5.0.0

gatk VariantFiltration -R ${path_to_reference} -V ${path_to_vcf} --filter-expression "DP < 100" --filter-name "user_specified_filter_depthOnly" -O ${outfile}
