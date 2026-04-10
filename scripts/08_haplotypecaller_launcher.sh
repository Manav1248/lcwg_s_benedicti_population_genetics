#!/bin/bash
# 08_haplotypecaller_launcher.sh - submit HaplotypeCaller GVCF array job

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/08_haplotypecaller.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/08_haplotypecaller.config"

[[ ! -f "${XFILE}" ]] && echo "ERROR: ${XFILE} not found" && exit 1
[[ ! -f "${GATK_SIF}" ]] && echo "ERROR: GATK container not found: ${GATK_SIF}" && exit 1
[[ ! -f "${REF_DIR}/Sbenedicti_v2.dict" ]] && echo "ERROR: sequence dictionary not found" && exit 1

NUM_SAMPLES=$(lc "${XFILE}")

# spot-check first BAM
FIRST=$(head -1 "${XFILE}")
FIRST_BAM="${GATK_BAM_DIR}/$(dirname "$FIRST")/$(basename "$FIRST").sorted.dedup.bam"
[[ ! -f "${FIRST_BAM}" ]] && echo "ERROR: BAM not found: ${FIRST_BAM}" && exit 1

create_dir $HC_DIR $GVCF_DIR $HC_LOGS_O $HC_LOGS_E
while IFS= read -r entry; do
    create_dir "${GVCF_DIR}/$(dirname "$entry")"
done < "$XFILE"

echo "Submitting ${JOB8_NAME} for ${NUM_SAMPLES} samples..."
awk -F/ '{print $1}' "$XFILE" | sort | uniq -c

bsub -J "${JOB8_NAME}[1-${NUM_SAMPLES}]%${JOB8_CONCURRENT}" \
     -n $JOB8_CPUS -W $JOB8_TIME \
     -R "span[hosts=1] rusage[mem=${JOB8_MEMORY}]" \
     -o "${HC_LOGS_O}/hc.08.%J_%I.log" \
     -e "${HC_LOGS_E}/hc.08.%J_%I.err" \
     bash "${SCRIPT_DIR}/08_haplotypecaller.sh"
