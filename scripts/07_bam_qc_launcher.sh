#!/bin/bash
# 07_bam_qc_launcher.sh - Launcher for BAM-level QC (Qualimap + mosdepth)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/07_bam_qc.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/07_bam_qc.config"
[[ ! -f "${XFILE}" ]] && echo "ERROR: ${XFILE} not found" && exit 1

NUM_SAMPLES=$(lc "${XFILE}")

[[ ! -d "${ANGSD_BAM_DIR}" ]] && echo "ERROR: ANGSD BAM dir not found: ${ANGSD_BAM_DIR}" && exit 1
[[ ! -d "${GATK_BAM_DIR}" ]]  && echo "ERROR: GATK BAM dir not found: ${GATK_BAM_DIR}" && exit 1

create_dir $BAM_QC $BAM_QC_LOGS_O $BAM_QC_LOGS_E \
           $QC_ANGSD_QUALIMAP $QC_ANGSD_MOSDEPTH \
           $QC_GATK_QUALIMAP $QC_GATK_MOSDEPTH

while IFS= read -r entry; do
    POPDIR=$(dirname "$entry")
    create_dir "${QC_ANGSD_QUALIMAP}/${POPDIR}" \
               "${QC_ANGSD_MOSDEPTH}/${POPDIR}" \
               "${QC_GATK_QUALIMAP}/${POPDIR}" \
               "${QC_GATK_MOSDEPTH}/${POPDIR}"
done < "$XFILE"

echo "Submitting ${JOB_NAME} for ${NUM_SAMPLES} samples..."
bsub -J "${JOB_NAME}[1-${NUM_SAMPLES}]%${NUM_SAMPLES}" \
     -n $JOB_CPUS -W $JOB_TIME \
     -R "span[hosts=1] rusage[mem=${JOB_MEMORY}]" \
     -o "${BAM_QC_LOGS_O}/bam_qc.07.%J_%I.log" \
     -e "${BAM_QC_LOGS_E}/bam_qc.07.%J_%I.err" \
     bash "${SCRIPT_DIR}/07_bam_qc.sh"
