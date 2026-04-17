#!/bin/bash
#BSUB -J 07_multiqc
#BSUB -n 1
#BSUB -W 01:00
#BSUB -R "rusage[mem=4GB]"
#BSUB -o logs/multiqc.07.%J.log
#BSUB -e logs/multiqc.07.%J.err

# 07_bam_qc_multiqc.sh - Aggregate Qualimap + mosdepth outputs into one report

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/07_bam_qc.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/07_bam_qc.config"

module load apptainer

echo "Running MultiQC for ANGSD BAMs..."
apptainer exec \
    --bind ${BAM_QC}:${BAM_QC} \
    $MULTIQC_SIF \
    multiqc \
        ${BAM_QC}/angsd/qualimap \
        ${BAM_QC}/angsd/mosdepth \
        -o ${BAM_QC} \
        -n multiqc_bam_qc_angsd \
        --force

echo "Running MultiQC for GATK BAMs..."
apptainer exec \
    --bind ${BAM_QC}:${BAM_QC} \
    $MULTIQC_SIF \
    multiqc \
        ${BAM_QC}/gatk/qualimap \
        ${BAM_QC}/gatk/mosdepth \
        -o ${BAM_QC} \
        -n multiqc_bam_qc_gatk \
        --force

echo "MultiQC (BAM QC) completed - two reports generated"; date
