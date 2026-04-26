#!/bin/bash

path_to_vcf="/scratch/bioconsult/zakas_project/snps.pass.vcf.gz"
path_to_reference="/scratch/bioconsult/zakas_project/gatk_downstream/reference/Sbenedicti_v2.fasta"
outfile="snps.pass.lowqualfiltered.vcf.gz"

#Below: using ${filter_expression} caused GATK to not detect the filter-expression option properly, had to hard-code it. Leaving these values below as reference.
#QUAL="0"
#MQ="50"
#SOR="3"
#QD="25"
#FS="60"
#MQRankSum="-10"
#ReadPosRankSum_Min="-5"
#ReadPosRankSum_Max="5"

#filter_name="QUAL < ${QUAL} || MQ < ${MQ} || SOR > ${SOR} || QD < ${QD} || FS > ${FS} || MQRankSum < ${MQRankSum} || ReadPosRankSum < ${ReadPosRankSum_Min} || ReadPosRankSum > ${ReadPosRankSum_Max}"

#echo $filter_expression

module load gatk/4.5.0.0

echo FILTERING SNP VCF
echo NOTE THAT THIS ONLY CHANGES THE PASS FLAG, ANOTHER SCRIPT WILL DO THE ACTUAL FILTERING
gatk VariantFiltration -R ${path_to_reference} -V ${path_to_vcf} --filter-expression "QUAL < 0 || MQ < 50.0 || SOR > 3.0 || QD < 25.0 || FS > 60.0 || MQRankSum < -10.0 || ReadPosRankSum < -5.0 || ReadPosRankSum > 5.0" --filter-name "user_specified_filter" -O ${outfile}
