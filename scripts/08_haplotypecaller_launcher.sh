#!/bin/bash
# 08_haplotypecaller_launcher.sh - submit HaplotypeCaller per sample x chromosome

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

CHR_LIST=${SCRIPT_DIR}/chromosome_list.txt
WORKER=${SCRIPT_DIR}/08_haplotypecaller_interval.sh

[[ ! -f "$XFILE" ]]   && echo "ERROR: ${XFILE} not found" && exit 1
[[ ! -f "$CHR_LIST" ]] && echo "ERROR: ${CHR_LIST} not found" && exit 1
[[ ! -f "$WORKER" ]]   && echo "ERROR: ${WORKER} not found" && exit 1

NUM_SAMPLES=$(wc -l < "$XFILE")
NUM_CHRS=$(wc -l < "$CHR_LIST")
echo "Submitting ${NUM_SAMPLES} samples x ${NUM_CHRS} chromosomes = $((NUM_SAMPLES * NUM_CHRS)) jobs"

create_dir $HC_DIR $GVCF_DIR $HC_LOGS_O $HC_LOGS_E

IDX=0
while IFS= read -r ENTRY; do
    IDX=$((IDX + 1))
    NAME=$(basename "$ENTRY")
    SUBDIR=$(dirname "$ENTRY")

    INTDIR=${GVCF_DIR}/${SUBDIR}/intervals_${NAME}
    mkdir -p "$INTDIR"

    echo "  [${IDX}] ${ENTRY}"

    while read CHR; do
        bsub -J "hc_${NAME}_${CHR}" \
             -n $JOB8_INT_CPUS -W $JOB8_INT_TIME \
             -R "span[hosts=1] rusage[mem=${JOB8_INT_MEMORY}]" \
             -o "${HC_LOGS_O}/hc.08.int.%J_${IDX}_${CHR}.log" \
             -e "${HC_LOGS_E}/hc.08.int.%J_${IDX}_${CHR}.err" \
             bash -c "export HC_SAMPLE_IDX=${IDX} HC_INTERVAL=${CHR}; bash ${WORKER}"
    done < "$CHR_LIST"

done < "$XFILE"

echo ""
echo "Submitted $((IDX * NUM_CHRS)) jobs. LSF handles scheduling."
echo "After all complete, run: bash 08_haplotypecaller_merge_intervals.sh"
