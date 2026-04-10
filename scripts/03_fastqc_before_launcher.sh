#!/bin/bash
# 03_fastqc_before_launcher.sh - Submit FastQC Before Trim (all populations, one array)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/03_fastqc_before.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"

source "${SCRIPT_DIR}/03_fastqc_before.config"

if [[ ! -f "${XFILE}" ]]; then
    echo "ERROR: Sample list file ${XFILE} not found!"
    echo "  Run generate_sample_list.sh first."
    exit 1
fi
NUM_SAMPLES=$(wc -l < "${XFILE}")

create_dir $FASTQC_BEFORE $FASTQC_LOGS_O $FASTQC_LOGS_E $FASTQC_B_HTML

echo "Submitting ${JOB3_NAME} for ${NUM_SAMPLES} samples across all populations..."

bsub -J "${JOB3_NAME}[1-${NUM_SAMPLES}]%${NUM_SAMPLES}" \
     -n $JOB3_CPUS \
     -W $JOB3_TIME \
     -R "span[hosts=1] rusage[mem=${JOB3_MEMORY}]" \
     -o "${FASTQC_LOGS_O}/fastqc.03.%J_%I.log" \
     -e "${FASTQC_LOGS_E}/fastqc.03.%J_%I.err" \
     < ${SCRIPT_DIR}/03_fastqc_before.sh

echo "Job submitted."
