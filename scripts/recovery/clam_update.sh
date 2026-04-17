#!/bin/bash
#BSUB -J clam_u01_rerun
#BSUB -n 8
#BSUB -W 4:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o /share/ivirus/dhermos/zakas_project/05_BWA_MEM2/out/clam_u01_rerun_%J.log
#BSUB -e /share/ivirus/dhermos/zakas_project/05_BWA_MEM2/out/clam_u01_rerun_%J.err

pwd; hostname; date

BWAMEM2_SIF=/rs1/shares/brc/admin/containers/images/bwa-mem2:2.2.1--hd03093a_5
SAMTOOLS_SIF=/rs1/shares/brc/admin/containers/images/staphb_samtools:1.21.sif
MOSDEPTH_SIF=/rs1/shares/brc/admin/containers/images/mosdepth_0_3_8.sif
REFERENCE=/rs1/shares/brc/admin/databases/s_benedicti/Sbenedicti_v2.fasta
TRIMMED=/share/ivirus/dhermos/zakas_project/04_TRIMMOMATIC/trimmed_reads
ANGSD_OUT=/share/ivirus/dhermos/zakas_project/05_BWA_MEM2/Clam
GATK_OUT=/share/ivirus/dhermos/zakas_project/05_BWA_MEM2/gatk_downstream/Clam
MOSDEPTH_OUT=/share/ivirus/dhermos/zakas_project/07_BAM_QC/gatk/mosdepth/Clam
TMPDIR=/share/ivirus/dhermos/zakas_project/tmp/Clam_U01
BIND=/rs1/shares/brc/admin:/rs1/shares/brc/admin,/share/ivirus/dhermos/zakas_project:/share/ivirus/dhermos/zakas_project

module load apptainer
mkdir -p ${TMPDIR} ${MOSDEPTH_OUT}

READ1=${TRIMMED}/Clam/Clam_U01_R1_paired.fastq.gz
READ2=${TRIMMED}/Clam/Clam_U01_R2_paired.fastq.gz
PU=$(zcat "$READ1" | head -1 | cut -d: -f3,4 --output-delimiter='.')
RG="@RG\tID:Clam_U01\tSM:Clam_U01\tPL:ILLUMINA\tPU:${PU}\tLB:Clam_U01"

echo "=== Aligning Clam_U01 ==="
apptainer exec --bind ${BIND} ${BWAMEM2_SIF} \
    bwa-mem2 mem -t 6 -R "${RG}" ${REFERENCE} ${READ1} ${READ2} | \
apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools fixmate -m -u - - | \
apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools sort -u -T ${TMPDIR} - | \
apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools markdup -S - ${ANGSD_OUT}/Clam_U01.sorted.markdup.bam

apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools index ${ANGSD_OUT}/Clam_U01.sorted.markdup.bam

apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools flagstat ${ANGSD_OUT}/Clam_U01.sorted.markdup.bam \
    > ${ANGSD_OUT}/Clam_U01.flagstat.txt

echo "=== Deduplicating for GATK ==="
apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools markdup -r -S --threads 4 \
    ${ANGSD_OUT}/Clam_U01.sorted.markdup.bam \
    ${GATK_OUT}/Clam_U01.sorted.dedup.bam

apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools index ${GATK_OUT}/Clam_U01.sorted.dedup.bam

apptainer exec --bind ${BIND} ${SAMTOOLS_SIF} \
    samtools flagstat ${GATK_OUT}/Clam_U01.sorted.dedup.bam \
    > ${GATK_OUT}/Clam_U01.flagstat.txt

echo "=== Running mosdepth ==="
apptainer exec --bind ${BIND} ${MOSDEPTH_SIF} \
    mosdepth --by 50000 --no-per-base --threads 4 \
    ${MOSDEPTH_OUT}/Clam_U01 \
    ${GATK_OUT}/Clam_U01.sorted.dedup.bam

rm -rf ${TMPDIR}
echo "=== Done ==="; date
