#!/bin/bash
#BSUB -J 07_multiqc
#BSUB -n 1
#BSUB -W 01:00
#BSUB -R "rusage[mem=4GB]"
#BSUB -o /share/ivirus/dhermos/zakas_project/07_BAM_QC/out/multiqc.07.%J.log
#BSUB -e /share/ivirus/dhermos/zakas_project/07_BAM_QC/err/multiqc.07.%J.err

# 07_bam_qc_multiqc.sh - Aggregate Qualimap + mosdepth outputs into one report

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/07_bam_qc.config

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

echo "MultiQC (BAM QC) completed — two reports generated"; date
