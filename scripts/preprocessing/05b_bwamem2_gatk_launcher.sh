#!/bin/bash
# 05b_bwamem2_gatk_launcher.sh - submit GATK-mode alignment (dups removed)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/05b_bwamem2_gatk.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/05b_bwamem2_gatk.config"

[[ ! -f "${XFILE}" ]] && echo "ERROR: ${XFILE} not found" && exit 1
[[ ! -f "${REFERENCE}.bwt.2bit.64" ]] && echo "ERROR: bwa index missing for ${REFERENCE}" && exit 1
[[ ! -f "${REFERENCE}.fai" ]] && echo "ERROR: faidx missing for ${REFERENCE}" && exit 1

NUM_SAMPLES=$(lc "${XFILE}")

create_dir $ALIGN_GATK_DIR $ALIGN_GATK_LOGS_O $ALIGN_GATK_LOGS_E
while IFS= read -r entry; do
    create_dir "${ALIGN_GATK_DIR}/$(dirname "$entry")"
done < "$XFILE"

echo "Submitting ${JOB5B_NAME} for ${NUM_SAMPLES} samples (GATK, dups removed)..."
awk -F/ '{print $1}' "$XFILE" | sort | uniq -c

bsub -J "${JOB5B_NAME}[1-${NUM_SAMPLES}]%${NUM_SAMPLES}" \
     -n $JOB5B_CPUS -W $JOB5B_TIME \
     -R "span[hosts=1] rusage[mem=${JOB5B_MEMORY}]" \
     -o "${ALIGN_GATK_LOGS_O}/bwa_gatk.05b.%J_%I.log" \
     -e "${ALIGN_GATK_LOGS_E}/bwa_gatk.05b.%J_%I.err" \
     bash "${SCRIPT_DIR}/05b_bwamem2_gatk.sh"
