#!/bin/bash
# 08_haplotypecaller_merge.sh - merge per-chromosome GVCFs into one per-sample GVCF
# chromosomes only, scaffolds excluded (<1% of genome)
# called with env var: HC_SAMPLE_IDX

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

CHR_LIST=${SCRIPT_DIR}/chromosome_list.txt

ENTRY=$(sed -n "${HC_SAMPLE_IDX}p" "$XFILE")
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")
OUTDIR=${GVCF_DIR}/${SUBDIR}
INTDIR=${OUTDIR}/intervals_${NAME}

echo "Merging: ${NAME} (${SUBDIR}) - 11 chromosomes"

# check all chromosome files exist
MISSING=0
while read CHR; do
    [[ ! -f "${INTDIR}/${NAME}.${CHR}.g.vcf.gz" ]] && echo "  Missing: ${CHR}" && MISSING=$((MISSING + 1))
done < "$CHR_LIST"

[[ $MISSING -gt 0 ]] && echo "Error: ${MISSING} chromosomes missing" && exit 1

# build -I arguments in dict order
INPUT_ARGS=""
while read CHR; do
    INPUT_ARGS="${INPUT_ARGS} -I ${INTDIR}/${NAME}.${CHR}.g.vcf.gz"
done < "$CHR_LIST"

module load apptainer

apptainer exec \
    --bind ${OUTDIR}:${OUTDIR},${INTDIR}:${INTDIR} \
    $GATK_SIF \
    gatk --java-options "${JOB8_MERGE_JAVA_HEAP}" \
        GatherVcfs \
        $INPUT_ARGS \
        -O ${OUTDIR}/${NAME}.g.vcf.gz

[[ $? -ne 0 ]] && echo "Error: GatherVcfs failed" && exit 1

apptainer exec \
    --bind ${OUTDIR}:${OUTDIR} \
    $GATK_SIF \
    gatk IndexFeatureFile -I ${OUTDIR}/${NAME}.g.vcf.gz

if [[ -f "${OUTDIR}/${NAME}.g.vcf.gz" && -f "${OUTDIR}/${NAME}.g.vcf.gz.tbi" ]]; then
    echo "Size: $(du -h "${OUTDIR}/${NAME}.g.vcf.gz" | cut -f1)"
else
    echo "Error: merge failed for ${NAME}"
    exit 1
fi

echo "Done: ${NAME}"; date
