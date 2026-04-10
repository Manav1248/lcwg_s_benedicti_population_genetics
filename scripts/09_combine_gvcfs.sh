#!/bin/bash
#BSUB -J combine_gvcfs
#BSUB -n 2
#BSUB -W 48:00
#BSUB -R "span[hosts=1] rusage[mem=24GB]"
#BSUB -o logs/combine_gvcfs_%J.log
#BSUB -e logs/combine_gvcfs_%J.err
# 09_combine_gvcfs.sh - merge per-sample GVCFs into one multi-sample GVCF

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

OUTPUT=${HC_DIR}/all_samples.g.vcf.gz
TMPDIR=${HC_DIR}/tmp_combine
mkdir -p "$TMPDIR"

# build -V arguments from sample list
GVCF_ARGS=""
MISSING=0
while IFS= read -r entry; do
    NAME=$(basename "$entry")
    SUBDIR=$(dirname "$entry")
    GVCF=${GVCF_DIR}/${SUBDIR}/${NAME}.g.vcf.gz
    if [[ ! -f "$GVCF" ]]; then
        echo "Warning: missing GVCF: $GVCF"
        MISSING=$((MISSING + 1))
    fi
    GVCF_ARGS="${GVCF_ARGS} -V ${GVCF}"
done < "$XFILE"

echo "GVCFs found: $(($(wc -l < "$XFILE") - MISSING)) / $(wc -l < "$XFILE")"
[[ $MISSING -gt 0 ]] && echo "WARNING: ${MISSING} GVCFs missing"

module load apptainer

echo "Running CombineGVCFs..."
apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "-Xmx22G -XX:ParallelGCThreads=1 -Djava.io.tmpdir=${TMPDIR}" \
        CombineGVCFs \
        -R $REFERENCE \
        $GVCF_ARGS \
        -O $OUTPUT

[[ $? -ne 0 ]] && echo "Error: CombineGVCFs failed" && rm -rf "$TMPDIR" && exit 1
[[ ! -f "$OUTPUT" ]] && echo "Error: output missing" && rm -rf "$TMPDIR" && exit 1

echo "Combined GVCF: $(du -h "$OUTPUT" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done"; date
