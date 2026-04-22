#!/bin/bash
# 13b_filter_indels.sh - select, filter, and extract PASS indels from all-sites VCF

set -euo pipefail
pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/13b_filter_indels.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/13b_filter_indels.config"

ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
OUTDIR=${GENOTYPED_DIR}/filtered

[[ ! -f "$ALLSITES_VCF" ]] && echo "Error: all-sites VCF not found — run 11b_gather first" && exit 1
mkdir -p "$OUTDIR"

module load apptainer
BCF="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR} $BCFTOOLS_SIF"

echo "Selecting indels..."
$BCF bcftools view -v indels $ALLSITES_VCF --threads ${BCFTOOLS_VIEW_THREADS} \
    -O z -o ${OUTDIR}/indels.raw.vcf.gz
$BCF bcftools index ${OUTDIR}/indels.raw.vcf.gz

echo "Filtering indels..."
$BCF bcftools filter ${OUTDIR}/indels.raw.vcf.gz \
    -e "${INDEL_FILTER}" \
    -s "hardfilter" \
    -O z -o ${OUTDIR}/indels.filtered.vcf.gz
$BCF bcftools index ${OUTDIR}/indels.filtered.vcf.gz

echo "Extracting PASS indels..."
$BCF bcftools view -f PASS ${OUTDIR}/indels.filtered.vcf.gz \
    -O z -o ${OUTDIR}/indels.pass.vcf.gz
$BCF bcftools index ${OUTDIR}/indels.pass.vcf.gz

echo "Extracting quality scores..."
echo -e "CHROM\tPOS\tQUAL\tQD\tDP\tMQ\tMQRankSum\tFS\tReadPosRankSum\tSOR" > ${OUTDIR}/indels.raw.table
$BCF bcftools query \
    -f '%CHROM\t%POS\t%QUAL\t%INFO/QD\t%INFO/DP\t%INFO/MQ\t%INFO/MQRankSum\t%INFO/FS\t%INFO/ReadPosRankSum\t%INFO/SOR\n' \
    ${OUTDIR}/indels.filtered.vcf.gz >> ${OUTDIR}/indels.raw.table

N=$($BCF bcftools view -H ${OUTDIR}/indels.filtered.vcf.gz | wc -l)
NPASS=$($BCF bcftools view -H ${OUTDIR}/indels.pass.vcf.gz | wc -l)
echo "Indels — filtered: ${N} | PASS: ${NPASS}"
echo "Done"; date
