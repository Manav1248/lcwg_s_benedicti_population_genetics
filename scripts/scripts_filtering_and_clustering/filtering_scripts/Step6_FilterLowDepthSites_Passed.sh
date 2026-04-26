#!/bin/bash

#Conda environment pixy_env must be activated for this script!!!

#VariantFiltration only adds flags indicating qualities of SNPs based on the filtration method used; need to actually filter for "PASS" flags.

echo FILTERING snps.pass.lowqualfiltered_passed_lowdepthfiltered.vcf.gz FOR PASSED VARIANTS
zgrep -E '^#|PASS' snps.pass.lowqualfiltered_passed_lowdepthfiltered.vcf.gz | bgzip > snps.pass.lowqualfiltered_passed_lowdepthfiltered_passed.vcf.gz
echo INDEXING OUTPUT VCF
tabix snps.pass.lowqualfiltered_passed_lowdepthfiltered_passed.vcf.gz
