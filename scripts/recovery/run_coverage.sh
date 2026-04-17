#!/bin/bash
#=============================================================================
# Step 1: Generate BAM list (run this part manually first)
#=============================================================================
# Run this ONCE from the login node before submitting the array job:
#
#   find /share/ivirus/dhermos/zakas_project/05_BWA_MEM2/gatk_downstream \
#       -name "*.sorted.dedup.bam" | sort > /share/ivirus/dhermos/zakas_project/qc_stats/bam_list.txt
#
#   wc -l /share/ivirus/dhermos/zakas_project/qc_stats/bam_list.txt
#   # ^ Use this number as the array max below
#
#   mkdir -p /share/ivirus/dhermos/zakas_project/qc_stats/coverage

#=============================================================================
# Step 2: Submit as array job
#=============================================================================
# Adjust the array range [1-N] to match the number of BAMs from wc -l above
#
#BSUB -J cov_stats[1-136]
#BSUB -n 1
#BSUB -W 01:00
#BSUB -R "rusage[mem=2GB]"
#BSUB -o /share/ivirus/dhermos/zakas_project/qc_stats/coverage/log_%I_%J.out
#BSUB -e /share/ivirus/dhermos/zakas_project/qc_stats/coverage/log_%I_%J.err

module load apptainer

SAMTOOLS_SIF=/rs1/shares/brc/admin/containers/images/staphb_samtools:1.21.sif
BAMLIST="/share/ivirus/dhermos/zakas_project/qc_stats/bam_list.txt"
OUTDIR="/share/ivirus/dhermos/zakas_project/qc_stats/coverage"
BAMDIR="/share/ivirus/dhermos/zakas_project/05_BWA_MEM2/gatk_downstream"

# Get this job's BAM file
BAM=$(sed -n "${LSB_JOBINDEX}p" "$BAMLIST")
SAMPLE=$(basename "$BAM" .sorted.dedup.bam)

echo "Processing: $SAMPLE"
echo "BAM: $BAM"

# Run samtools coverage with explicit bind mounts
apptainer exec \
    --bind ${BAMDIR}:${BAMDIR},${OUTDIR}:${OUTDIR} \
    $SAMTOOLS_SIF \
    samtools coverage "$BAM" > "${OUTDIR}/${SAMPLE}.coverage.txt"

# Compute genome-wide weighted mean coverage and breadth
awk 'NR>1 && $3>0 {
    bases += $3;
    depth_sum += $7 * $3;
    cov_sum += $6 * $3;
}END{
    printf "%s\t%.2f\t%.2f\n", SAMPLE, depth_sum/bases, cov_sum/bases
}' SAMPLE="$SAMPLE" "${OUTDIR}/${SAMPLE}.coverage.txt" > "${OUTDIR}/${SAMPLE}.summary.txt"

echo "Done: $SAMPLE"
