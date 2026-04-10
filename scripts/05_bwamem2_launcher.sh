#!/bin/bash
# 05_bwamem2_launcher.sh - submit ANGSD-mode alignment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/05_bwamem2.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/05_bwamem2.config"

[[ ! -f "${XFILE}" ]] && echo "ERROR: ${XFILE} not found" && exit 1
[[ ! -f "${REFERENCE}.bwt.2bit.64" ]] && echo "ERROR: bwa index missing for ${REFERENCE}" && exit 1
[[ ! -f "${REFERENCE}.fai" ]] && echo "ERROR: faidx missing for ${REFERENCE}" && exit 1

NUM_SAMPLES=$(lc "${XFILE}")

create_dir $ALIGN_DIR $ALIGN_LOGS_O $ALIGN_LOGS_E
while IFS= read -r entry; do
    create_dir "${ALIGN_DIR}/$(dirname "$entry")"
done < "$XFILE"

echo "Submitting ${JOB5_NAME} for ${NUM_SAMPLES} samples..."
awk -F/ '{print $1}' "$XFILE" | sort | uniq -c

bsub -J "${JOB5_NAME}[1-${NUM_SAMPLES}]%${NUM_SAMPLES}" \
     -n $JOB5_CPUS -W $JOB5_TIME \
     -R "span[hosts=1] rusage[mem=${JOB5_MEMORY}]" \
     -o "${ALIGN_LOGS_O}/bwa.05.%J_%I.log" \
     -e "${ALIGN_LOGS_E}/bwa.05.%J_%I.err" \
     bash "${SCRIPT_DIR}/05_bwamem2.sh"
