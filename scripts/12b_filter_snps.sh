#!/bin/bash
# 12b_filter_snps.sh - select, filter, and extract PASS SNPs from all-sites VCF

set -euo pipefail
pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/12b_filter_snps.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/12b_filter_snps.config"

ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
OUTDIR=${GENOTYPED_DIR}/filtered

[[ ! -f "$ALLSITES_VCF" ]] && echo "Error: all-sites VCF not found — run 11b_gather first" && exit 1
mkdir -p "$OUTDIR"

module load apptainer
BCF="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR} $BCFTOOLS_SIF"

echo "Selecting SNPs..."
$BCF bcftools view -v snps $ALLSITES_VCF --threads ${BCFTOOLS_VIEW_THREADS} \
    -O z -o ${OUTDIR}/snps.raw.vcf.gz
$BCF bcftools index ${OUTDIR}/snps.raw.vcf.gz

echo "Filtering SNPs..."
$BCF bcftools filter ${OUTDIR}/snps.raw.vcf.gz \
    -e "${SNP_FILTER}" \
    -s "hardfilter" \
    -O z -o ${OUTDIR}/snps.filtered.vcf.gz
$BCF bcftools index ${OUTDIR}/snps.filtered.vcf.gz

echo "Extracting PASS SNPs..."
$BCF bcftools view -f PASS ${OUTDIR}/snps.filtered.vcf.gz \
    -O z -o ${OUTDIR}/snps.pass.vcf.gz
$BCF bcftools index ${OUTDIR}/snps.pass.vcf.gz

echo "Extracting quality scores..."
echo -e "CHROM\tPOS\tQUAL\tQD\tDP\tMQ\tMQRankSum\tFS\tReadPosRankSum\tSOR" > ${OUTDIR}/snps.raw.table
$BCF bcftools query \
    -f '%CHROM\t%POS\t%QUAL\t%INFO/QD\t%INFO/DP\t%INFO/MQ\t%INFO/MQRankSum\t%INFO/FS\t%INFO/ReadPosRankSum\t%INFO/SOR\n' \
    ${OUTDIR}/snps.filtered.vcf.gz >> ${OUTDIR}/snps.raw.table

N=$($BCF bcftools view -H ${OUTDIR}/snps.filtered.vcf.gz | wc -l)
NPASS=$($BCF bcftools view -H ${OUTDIR}/snps.pass.vcf.gz | wc -l)
echo "SNPs — filtered: ${N} | PASS: ${NPASS}"
echo "Done"; date
