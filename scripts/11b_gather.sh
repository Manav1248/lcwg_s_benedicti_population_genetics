#!/bin/bash
# 11b_gather.sh - fix chunk VCFs in parallel and concatenate into all-sites VCF

set -euo pipefail
pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/11b_gather.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/11b_gather.config"

CHUNK_DIR=${GENOTYPED_DIR}/by_chunk
FIXED_DIR=${GENOTYPED_DIR}/by_chunk_fixed
ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz

NCHUNKS=$(ls ${CHUNK_DIR}/chunk_*.vcf.gz 2>/dev/null | wc -l)
[[ $NCHUNKS -eq 0 ]] && echo "Error: no chunk VCFs found in ${CHUNK_DIR}" && exit 1

mkdir -p "$FIXED_DIR"
module load apptainer

BCF="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR} $BCFTOOLS_SIF"

echo "Fixing ${NCHUNKS} chunk VCFs (${BCFTOOLS_MAX_PARALLEL} parallel)..."
for f in $(ls ${CHUNK_DIR}/chunk_*.vcf.gz | sort); do
    BASE=$(basename "$f")
    (
        $BCF bcftools view $f --threads ${BCFTOOLS_FIX_THREADS} -O z -o ${FIXED_DIR}/${BASE} 2>/dev/null
        $BCF bcftools index ${FIXED_DIR}/${BASE}
        echo "  Fixed ${BASE}"
    ) &
    RUNNING=$(jobs -rp | wc -l)
    while [[ $RUNNING -ge $BCFTOOLS_MAX_PARALLEL ]]; do
        sleep 2
        RUNNING=$(jobs -rp | wc -l)
    done
done
wait
echo "All chunks fixed"

FIXED_COUNT=$(ls ${FIXED_DIR}/chunk_*.vcf.gz 2>/dev/null | wc -l)
[[ $FIXED_COUNT -ne $NCHUNKS ]] && echo "Error: only ${FIXED_COUNT}/${NCHUNKS} chunks fixed" && exit 1

echo "Concatenating ${FIXED_COUNT} chunks..."
ls ${FIXED_DIR}/chunk_*.vcf.gz | sort > ${FIXED_DIR}/chunk_list.txt
$BCF bcftools concat \
    --naive \
    --file-list ${FIXED_DIR}/chunk_list.txt \
    -O z \
    -o $ALLSITES_VCF

$BCF bcftools index $ALLSITES_VCF
echo "All-sites VCF: $(du -h "$ALLSITES_VCF" | cut -f1)"

rm -rf "$FIXED_DIR"
echo "Done"; date
