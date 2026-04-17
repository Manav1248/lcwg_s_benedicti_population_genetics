#!/bin/bash
# 08_haplotypecaller_by_interval.sh - split slow samples by chromosome
# submits all jobs and exits, LSF handles scheduling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

RERUN_LIST=${SCRIPT_DIR}/hc_rerun2_indices.txt
CHR_LIST=${SCRIPT_DIR}/chromosome_list.txt
WORKER=${SCRIPT_DIR}/08_haplotypecaller_interval.sh

[[ ! -f "$RERUN_LIST" ]] && echo "ERROR: ${RERUN_LIST} not found" && exit 1
[[ ! -f "$CHR_LIST" ]] && echo "ERROR: ${CHR_LIST} not found" && exit 1
[[ ! -f "$WORKER" ]] && echo "ERROR: ${WORKER} not found" && exit 1

NUM_SAMPLES=$(wc -l < "$RERUN_LIST")
NUM_CHRS=$(wc -l < "$CHR_LIST")
TOTAL_JOBS=$((NUM_SAMPLES * NUM_CHRS))
echo "Submitting ${NUM_SAMPLES} samples x ${NUM_CHRS} chromosomes = ${TOTAL_JOBS} jobs"

SUBMITTED=0

while read IDX; do
    ENTRY=$(sed -n "${IDX}p" "$XFILE")
    NAME=$(basename "$ENTRY")
    SUBDIR=$(dirname "$ENTRY")

    # clean up partial whole-genome output
    OUTDIR=${GVCF_DIR}/${SUBDIR}
    rm -f "${OUTDIR}/${NAME}.g.vcf.gz" "${OUTDIR}/${NAME}.g.vcf.gz.tbi"
    rm -rf "${OUTDIR}/tmp_${NAME}"

    INTDIR=${GVCF_DIR}/${SUBDIR}/intervals_${NAME}
    mkdir -p "$INTDIR"

    echo "  [${IDX}] ${ENTRY}"

    # one job per chromosome
    while read CHR; do
        bsub -J "hc_${NAME}_${CHR}" \
             -n $JOB8_INT_CPUS -W $JOB8_INT_TIME \
             -R "span[hosts=1] rusage[mem=${JOB8_INT_MEMORY}]" \
             -o "${HC_LOGS_O}/hc.08.int.%J_${IDX}_${CHR}.log" \
             -e "${HC_LOGS_E}/hc.08.int.%J_${IDX}_${CHR}.err" \
             bash -c "export HC_SAMPLE_IDX=${IDX} HC_INTERVAL=${CHR} HC_INTERVAL_TYPE=chr; bash ${WORKER}"
        SUBMITTED=$((SUBMITTED + 1))
    done < "$CHR_LIST"

done < "$RERUN_LIST"

echo ""
echo "Submitted ${SUBMITTED} jobs. LSF handles scheduling."
echo "After all complete, run: bash 08_haplotypecaller_merge_intervals.sh"
