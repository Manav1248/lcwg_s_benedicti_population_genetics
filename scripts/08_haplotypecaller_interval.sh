#!/bin/bash
# 08_haplotypecaller_interval.sh - per-sample per-interval HaplotypeCaller
# called with env vars: HC_SAMPLE_IDX, HC_INTERVAL, HC_INTERVAL_TYPE

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

# resolve sample from passed index
ENTRY=$(sed -n "${HC_SAMPLE_IDX}p" "$XFILE")
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")
echo "Sample: ${NAME} (${SUBDIR}) | Interval: ${HC_INTERVAL} (${HC_INTERVAL_TYPE})"

INPUT_BAM=${GATK_BAM_DIR}/${SUBDIR}/${NAME}.sorted.dedup.bam
INTDIR=${GVCF_DIR}/${SUBDIR}/intervals_${NAME}

# set output name and -L argument based on type
if [[ "$HC_INTERVAL_TYPE" == "scaffold" ]]; then
    OUTPUT_GVCF=${INTDIR}/${NAME}.scaffolds.g.vcf.gz
    INTERVAL_ARG="-L ${HC_INTERVAL}"
else
    OUTPUT_GVCF=${INTDIR}/${NAME}.${HC_INTERVAL}.g.vcf.gz
    INTERVAL_ARG="-L ${HC_INTERVAL}"
fi

TMPDIR=${INTDIR}/tmp_${HC_INTERVAL_TYPE}_${HC_INTERVAL}
mkdir -p "$INTDIR" "$TMPDIR"

[[ ! -f "$INPUT_BAM" ]] && echo "Error: BAM not found: $INPUT_BAM" && exit 1
[[ ! -f "${INPUT_BAM}.bai" ]] && echo "Error: BAM index not found: ${INPUT_BAM}.bai" && exit 1

module load apptainer

BIND_PATHS="${GATK_BAM_DIR}:${GATK_BAM_DIR},${REF_DIR}:${REF_DIR},${INTDIR}:${INTDIR},${TMPDIR}:${TMPDIR}"
if [[ "$HC_INTERVAL_TYPE" == "scaffold" ]]; then
    BIND_PATHS="${BIND_PATHS},${SCRIPT_DIR}:${SCRIPT_DIR}"
fi

apptainer exec \
    --bind ${BIND_PATHS} \
    $GATK_SIF \
    gatk --java-options "-Xmx10G -XX:ParallelGCThreads=2 -Djava.io.tmpdir=${TMPDIR}" \
        HaplotypeCaller \
        -R $REFERENCE \
        -I $INPUT_BAM \
        -O $OUTPUT_GVCF \
        -ERC GVCF \
        --native-pair-hmm-threads 4 \
        $INTERVAL_ARG

[[ $? -ne 0 ]] && echo "Error: HaplotypeCaller failed" && rm -rf "$TMPDIR" && exit 1
[[ ! -f "$OUTPUT_GVCF" ]] && echo "Error: output missing: $OUTPUT_GVCF" && rm -rf "$TMPDIR" && exit 1

echo "GVCF: $(du -h "$OUTPUT_GVCF" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done: ${NAME} ${HC_INTERVAL}"; date
