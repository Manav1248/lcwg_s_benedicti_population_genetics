#!/bin/bash
# 08_haplotypecaller_merge_intervals.sh - submit merge jobs for interval-split samples

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

RERUN_LIST=${SCRIPT_DIR}/hc_rerun2_indices.txt
WORKER=${SCRIPT_DIR}/08_haplotypecaller_merge.sh

[[ ! -f "$RERUN_LIST" ]] && echo "ERROR: ${RERUN_LIST} not found" && exit 1
[[ ! -f "$WORKER" ]] && echo "ERROR: ${WORKER} not found" && exit 1

NUM_SAMPLES=$(wc -l < "$RERUN_LIST")
echo "Submitting merge jobs for ${NUM_SAMPLES} samples..."

while read IDX; do
    ENTRY=$(sed -n "${IDX}p" "$XFILE")
    NAME=$(basename "$ENTRY")

    echo "  [${IDX}] ${NAME}"

    bsub -J "merge_${NAME}" \
         -n 2 -W 2:00 \
         -R "span[hosts=1] rusage[mem=8GB]" \
         -o "${HC_LOGS_O}/hc.08.merge.%J_${IDX}.log" \
         -e "${HC_LOGS_E}/hc.08.merge.%J_${IDX}.err" \
         bash -c "export HC_SAMPLE_IDX=${IDX}; bash ${WORKER}"

done < "$RERUN_LIST"
