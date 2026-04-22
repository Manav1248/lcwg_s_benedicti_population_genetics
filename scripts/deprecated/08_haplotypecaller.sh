#!/bin/bash
# 08_haplotypecaller.sh - per-sample GVCF generation
# dedup BAM -> HaplotypeCaller -ERC GVCF -> .g.vcf.gz

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

ENTRY=$(get_sample_entry)
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")
echo "Sample: ${NAME} (${SUBDIR})"

INPUT_BAM=${GATK_BAM_DIR}/${SUBDIR}/${NAME}.sorted.dedup.bam
OUTDIR=${GVCF_DIR}/${SUBDIR}
OUTPUT_GVCF=${OUTDIR}/${NAME}.g.vcf.gz
TMPDIR=${OUTDIR}/tmp_${NAME}

[[ ! -f "$INPUT_BAM" ]] && echo "Error: BAM not found: $INPUT_BAM" && exit 1
[[ ! -f "${INPUT_BAM}.bai" ]] && echo "Error: BAM index not found: ${INPUT_BAM}.bai" && exit 1

mkdir -p "$OUTDIR" "$TMPDIR"

module load apptainer

apptainer exec \
    --bind ${GATK_BAM_DIR}:${GATK_BAM_DIR},${REF_DIR}:${REF_DIR},${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "-Xmx10G -XX:ParallelGCThreads=1 -Djava.io.tmpdir=${TMPDIR}" \
        HaplotypeCaller \
        -R $REFERENCE \
        -I $INPUT_BAM \
        -O $OUTPUT_GVCF \
        -ERC GVCF \
        --native-pair-hmm-threads 1

[[ $? -ne 0 ]] && echo "Error: HaplotypeCaller failed" && rm -rf "$TMPDIR" && exit 1
[[ ! -f "$OUTPUT_GVCF" ]] && echo "Error: output missing: $OUTPUT_GVCF" && rm -rf "$TMPDIR" && exit 1

echo "GVCF: $(du -h "$OUTPUT_GVCF" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done: ${NAME}"; date
