#!/bin/bash
# 08_haplotypecaller_merge_intervals.sh - submit merge jobs for all samples

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

WORKER=${SCRIPT_DIR}/08_haplotypecaller_merge.sh

[[ ! -f "$XFILE" ]]  && echo "ERROR: ${XFILE} not found" && exit 1
[[ ! -f "$WORKER" ]] && echo "ERROR: ${WORKER} not found" && exit 1

NUM_SAMPLES=$(wc -l < "$XFILE")
echo "Submitting merge jobs for ${NUM_SAMPLES} samples..."

IDX=0
while IFS= read -r ENTRY; do
    IDX=$((IDX + 1))
    NAME=$(basename "$ENTRY")

    echo "  [${IDX}] ${NAME}"

    bsub -J "merge_${NAME}" \
         -n $JOB8_MERGE_CPUS -W $JOB8_MERGE_TIME \
         -R "span[hosts=1] rusage[mem=${JOB8_MERGE_MEMORY}]" \
         -o "${HC_LOGS_O}/hc.08.merge.%J_${IDX}.log" \
         -e "${HC_LOGS_E}/hc.08.merge.%J_${IDX}.err" \
         bash -c "export HC_SAMPLE_IDX=${IDX}; bash ${WORKER}"

done < "$XFILE"
