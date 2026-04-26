#!/bin/bash

path_to_reference="/scratch/bioconsult/zakas_project/gatk_downstream/reference/Sbenedicti_v2.fasta"
path_to_vcf="/scratch/bioconsult/zakas_project/SNV_Calls_Filtered/snps.pass.lowqualfiltered_passed_lowdepthfiltered_passed.vcf.gz"
outfile="QualityScores_SNPVCF_LowQualSitesFiltered_DPFiltered.table"

module load gatk/4.5.0.0
echo GETTING QUALITY SCORES FROM: ${path_to_vcf}
gatk VariantsToTable -R ${path_to_reference} -V ${path_to_vcf} -F CHROM -F POS -F QUAL -F QD -F DP -F MQ -F MQRankSum -F FS -F ReadPosRankSum -F SOR -O ${outfile}

