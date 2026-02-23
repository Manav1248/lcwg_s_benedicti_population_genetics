#!/bin/bash
#BSUB -J bwa_rerun[1-3]
#BSUB -n 8
#BSUB -W 08:00
#BSUB -R "span[hosts=1] rusage[mem=24GB]"
#BSUB -o /share/ivirus/dhermos/zakas_project/05_BWA_MEM2/out/rerun_%I_%J.out
#BSUB -e /share/ivirus/dhermos/zakas_project/05_BWA_MEM2/err/rerun_%I_%J.err
# Re-run 3 high-mem samples (doubled mem/walltime) only due to 3 samples

pwd; hostname; date

PROJECT=/share/ivirus/dhermos/zakas_project
TRIM_BASE=${PROJECT}/04_TRIMMOMATIC/trimmed_reads
REFERENCE=/rs1/shares/brc/admin/databases/s_benedicti/Sbenedicti_v2.fasta
BWAMEM2_SIF=${PROJECT}/containers/bwa-mem2:2.2.1--hd03093a_5
SAMTOOLS_SIF=/rs1/shares/brc/admin/containers/images/staphb_samtools:1.21.sif
ALIGN_DIR=${PROJECT}/05_BWA_MEM2
GATK_DIR=${ALIGN_DIR}/gatk_downstream

module load apptainer

SAMPLES=("Gal/Gal_L_F09" "LBA/LBA_L_F01" "LBA/LBA_L_F03")
ENTRY=${SAMPLES[$LSB_JOBINDEX-1]}
SUBDIR=$(dirname "$ENTRY")
SAMPLE=$(basename "$ENTRY")
echo "Processing: ${SAMPLE} (${ENTRY})"

READ1=${TRIM_BASE}/${SUBDIR}/${SAMPLE}_R1_paired.fastq.gz
READ2=${TRIM_BASE}/${SUBDIR}/${SAMPLE}_R2_paired.fastq.gz

# read group
HEADER=$(apptainer exec --bind ${TRIM_BASE}:${TRIM_BASE} $SAMTOOLS_SIF bash -c "zcat $READ1 | head -1")
PU="$(echo "$HEADER" | cut -d: -f3).$(echo "$HEADER" | cut -d: -f4)"
RG="@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tLB:${SAMPLE}\tPL:ILLUMINA\tPU:${PU}"

REF_DIR=$(dirname $REFERENCE)
ANGSD_OUT=${ALIGN_DIR}/${SUBDIR}
GATK_OUT=${GATK_DIR}/${SUBDIR}
mkdir -p "$ANGSD_OUT" "$GATK_OUT"
TMPDIR_A=${ANGSD_OUT}/tmp_${SAMPLE}
TMPDIR_G=${GATK_OUT}/tmp_${SAMPLE}
mkdir -p "$TMPDIR_A" "$TMPDIR_G"

# ANGSD
echo "=== ANGSD pipeline ==="
apptainer exec --bind ${TRIM_BASE}:${TRIM_BASE},${REF_DIR}:${REF_DIR},${ALIGN_DIR}:${ALIGN_DIR} \
    $BWAMEM2_SIF bwa-mem2 mem -t 8 -R "${RG}" ${REFERENCE} ${READ1} ${READ2} \
| apptainer exec --bind ${ANGSD_OUT}:${ANGSD_OUT} $SAMTOOLS_SIF samtools fixmate -m -u - - \
| apptainer exec --bind ${ANGSD_OUT}:${ANGSD_OUT} $SAMTOOLS_SIF samtools sort -@ 4 -m 4G -T ${TMPDIR_A}/${SAMPLE} -u - \
| apptainer exec --bind ${ANGSD_OUT}:${ANGSD_OUT} $SAMTOOLS_SIF samtools markdup -S - ${ANGSD_OUT}/${SAMPLE}.sorted.markdup.bam

apptainer exec --bind ${ANGSD_OUT}:${ANGSD_OUT} $SAMTOOLS_SIF samtools index ${ANGSD_OUT}/${SAMPLE}.sorted.markdup.bam
apptainer exec --bind ${ANGSD_OUT}:${ANGSD_OUT} $SAMTOOLS_SIF samtools flagstat ${ANGSD_OUT}/${SAMPLE}.sorted.markdup.bam > ${ANGSD_OUT}/${SAMPLE}.flagstat.txt
echo "ANGSD done: $(ls -lh ${ANGSD_OUT}/${SAMPLE}.sorted.markdup.bam | awk '{print $5}')"

# GATK
echo "=== GATK pipeline ==="
apptainer exec --bind ${TRIM_BASE}:${TRIM_BASE},${REF_DIR}:${REF_DIR},${GATK_DIR}:${GATK_DIR} \
    $BWAMEM2_SIF bwa-mem2 mem -t 8 -R "${RG}" ${REFERENCE} ${READ1} ${READ2} \
| apptainer exec --bind ${GATK_OUT}:${GATK_OUT} $SAMTOOLS_SIF samtools fixmate -m -u - - \
| apptainer exec --bind ${GATK_OUT}:${GATK_OUT} $SAMTOOLS_SIF samtools sort -@ 4 -m 4G -T ${TMPDIR_G}/${SAMPLE} -u - \
| apptainer exec --bind ${GATK_OUT}:${GATK_OUT} $SAMTOOLS_SIF samtools markdup -r -S - ${GATK_OUT}/${SAMPLE}.sorted.dedup.bam

apptainer exec --bind ${GATK_OUT}:${GATK_OUT} $SAMTOOLS_SIF samtools index ${GATK_OUT}/${SAMPLE}.sorted.dedup.bam
apptainer exec --bind ${GATK_OUT}:${GATK_OUT} $SAMTOOLS_SIF samtools flagstat ${GATK_OUT}/${SAMPLE}.sorted.dedup.bam > ${GATK_OUT}/${SAMPLE}.flagstat.txt
echo "GATK done: $(ls -lh ${GATK_OUT}/${SAMPLE}.sorted.dedup.bam | awk '{print $5}')"

rm -rf "$TMPDIR_A" "$TMPDIR_G"
echo "=== ${SAMPLE} complete ==="; date
