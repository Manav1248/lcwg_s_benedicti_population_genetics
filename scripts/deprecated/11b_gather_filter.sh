#!/bin/bash
#BSUB -J gather_filter
#BSUB -n 8
#BSUB -W 12:00
#BSUB -R "span[hosts=1] rusage[mem=24GB]"
#BSUB -o logs/gather_filter_%J.log
#BSUB -e logs/gather_filter_%J.err
# 11b_gather_filter.sh - fix chunk VCFs in parallel, merge, filter with bcftools

set -euo pipefail

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/11b_gather_filter.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/11b_gather_filter.config"
CHUNK_DIR=${GENOTYPED_DIR}/by_chunk
FIXED_DIR=${GENOTYPED_DIR}/by_chunk_fixed
ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
OUTDIR=${GENOTYPED_DIR}/filtered
mkdir -p "$OUTDIR" "$FIXED_DIR"

module load apptainer

BCF="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $BCFTOOLS_SIF"

NCHUNKS=$(ls ${CHUNK_DIR}/chunk_*.vcf.gz 2>/dev/null | wc -l)
[[ $NCHUNKS -eq 0 ]] && echo "Error: no chunk VCFs found" && exit 1

# rewrite chunks in parallel (4 at a time) to fix BGZF blocks
echo "Fixing ${NCHUNKS} chunk VCFs (4 parallel)..."
MAX_PARALLEL=${BCFTOOLS_MAX_PARALLEL}
for f in $(ls ${CHUNK_DIR}/chunk_*.vcf.gz | sort); do
    BASE=$(basename "$f")
    (
        $BCF bcftools view $f --threads ${BCFTOOLS_FIX_THREADS} -O z -o ${FIXED_DIR}/${BASE} 2>/dev/null
        $BCF bcftools index ${FIXED_DIR}/${BASE}
        echo "  Fixed ${BASE}"
    ) &
    RUNNING=$(jobs -rp | wc -l)
    while [[ $RUNNING -ge $MAX_PARALLEL ]]; do
        sleep 2
        RUNNING=$(jobs -rp | wc -l)
    done
done
wait
echo "All chunks fixed"

# verify all fixed chunks exist
FIXED_COUNT=$(ls ${FIXED_DIR}/chunk_*.vcf.gz 2>/dev/null | wc -l)
[[ $FIXED_COUNT -ne $NCHUNKS ]] && echo "Error: only ${FIXED_COUNT}/${NCHUNKS} chunks fixed" && exit 1

# naive concat (fast block copy, no decompression)
echo "Concatenating with naive block copy..."
ls ${FIXED_DIR}/chunk_*.vcf.gz | sort > ${FIXED_DIR}/chunk_list.txt
$BCF bcftools concat \
    --naive \
    --file-list ${FIXED_DIR}/chunk_list.txt \
    -O z \
    -o $ALLSITES_VCF

$BCF bcftools index $ALLSITES_VCF
echo "All-sites VCF: $(du -h "$ALLSITES_VCF" | cut -f1)"

# SNPs: select -> filter -> extract PASS
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

# indels: select -> filter -> extract PASS
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

# counts
echo ""
echo "Site counts:"
for f in snps.filtered snps.pass indels.filtered indels.pass; do
    N=$($BCF bcftools view -H ${OUTDIR}/${f}.vcf.gz | wc -l)
    echo "${f}: ${N}"
done

# quality score tables for diagnostic plots
echo "Extracting quality scores..."
echo -e "CHROM\tPOS\tQUAL\tQD\tDP\tMQ\tMQRankSum\tFS\tReadPosRankSum\tSOR" > ${OUTDIR}/snps.raw.table
$BCF bcftools query -f '%CHROM\t%POS\t%QUAL\t%INFO/QD\t%INFO/DP\t%INFO/MQ\t%INFO/MQRankSum\t%INFO/FS\t%INFO/ReadPosRankSum\t%INFO/SOR\n' \
    ${OUTDIR}/snps.filtered.vcf.gz >> ${OUTDIR}/snps.raw.table

echo -e "CHROM\tPOS\tQUAL\tQD\tDP\tMQ\tMQRankSum\tFS\tReadPosRankSum\tSOR" > ${OUTDIR}/indels.raw.table
$BCF bcftools query -f '%CHROM\t%POS\t%QUAL\t%INFO/QD\t%INFO/DP\t%INFO/MQ\t%INFO/MQRankSum\t%INFO/FS\t%INFO/ReadPosRankSum\t%INFO/SOR\n' \
    ${OUTDIR}/indels.filtered.vcf.gz >> ${OUTDIR}/indels.raw.table

# clean up
rm -rf "$FIXED_DIR"

echo "Done"; date
