#!/bin/bash
# 04_trimmomatic_launcher.sh - Submit Trimmomatic (all populations, one array)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/04_trimmomatic.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"

source "${SCRIPT_DIR}/04_trimmomatic.config"

if [[ ! -f "${XFILE}" ]]; then
    echo "ERROR: Sample list file ${XFILE} not found!"
    echo "  Run generate_sample_list.sh first."
    exit 1
fi
NUM_SAMPLES=$(wc -l < "${XFILE}")

# Create output dirs for each population
while IFS= read -r entry; do
    subdir=$(dirname "$entry")
    create_dir "${TRIMMED}/${subdir}" "${UNPAIRED}/${subdir}"
done < "$XFILE"

create_dir $TRIM_DIR $TRIM_LOGS_O $TRIM_LOGS_E \
           $WORKING_DIR/06_FASTQC_AFTER/htmls

echo "Submitting ${JOB4_NAME} for ${NUM_SAMPLES} samples across all populations..."
echo "  Sample list: ${XFILE}"

# Show population breakdown
echo "  Populations:"
awk -F/ '{print $1}' "$XFILE" | sort | uniq -c | while read count pop; do
    echo "    ${pop}: ${count} samples"
done

bsub -J "${JOB4_NAME}[1-${NUM_SAMPLES}]%${NUM_SAMPLES}" \
     -n $JOB4_CPUS \
     -W $JOB4_TIME \
     -R "span[hosts=1] rusage[mem=${JOB4_MEMORY}]" \
     -o "${TRIM_LOGS_O}/trim.04.%J_%I.log" \
     -e "${TRIM_LOGS_E}/trim.04.%J_%I.err" \
     < ${SCRIPT_DIR}/04_trimmomatic.sh

echo "Job submitted. Monitor with: bjobs -J ${JOB4_NAME}"
