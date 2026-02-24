#!/bin/bash
# 04_trimmomatic_launcher.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/04_trimmomatic.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/04_trimmomatic.config"

[[ ! -f "${XFILE}" ]] && echo "ERROR: ${XFILE} not found" && exit 1
NUM_SAMPLES=$(lc "${XFILE}")

create_dir $TRIM_DIR $TRIM_LOGS_O $TRIM_LOGS_E $WORKING_DIR/06_FASTQC_AFTER/htmls
while IFS= read -r entry; do
    subdir=$(dirname "$entry")
    create_dir "${TRIMMED}/${subdir}" "${UNPAIRED}/${subdir}"
done < "$XFILE"

echo "Submitting ${JOB4_NAME} for ${NUM_SAMPLES} samples..."
awk -F/ '{print $1}' "$XFILE" | sort | uniq -c

bsub -J "${JOB4_NAME}[1-${NUM_SAMPLES}]%${NUM_SAMPLES}" \
     -n $JOB4_CPUS -W $JOB4_TIME \
     -R "span[hosts=1] rusage[mem=${JOB4_MEMORY}]" \
     -o "${TRIM_LOGS_O}/trim.04.%J_%I.log" \
     -e "${TRIM_LOGS_E}/trim.04.%J_%I.err" \
     bash "${SCRIPT_DIR}/04_trimmomatic.sh"
