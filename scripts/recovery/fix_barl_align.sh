#!/bin/bash
#BSUB -J barl_align[1-16]
#BSUB -n 8
#BSUB -W 04:00
#BSUB -R "span[hosts=1] rusage[mem=12GB]"
#BSUB -o scripts/logs/barl_align.%J_%I.log
#BSUB -e scripts/logs/barl_align.%J_%I.err
# fix_barl_align.sh - re-align Bar_L samples after scratch purge
# generates ANGSD BAMs (markdup flagged, not removed)

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

BWAMEM2_SIF=/rs1/shares/brc/admin/containers/images/bwa-mem2:2.2.1--hd03093a_5
SAMTOOLS_SIF=/rs1/shares/brc/admin/containers/images/staphb_samtools:1.21.sif

SAMPLES=(
    Bar_L_F01 Bar_L_F02 Bar_L_F03 Bar_L_F04
    Bar_L_F05 Bar_L_F06 Bar_L_F07 Bar_L_F08
    Bar_L_F09 Bar_L_F10 Bar_L_F11 Bar_L_F12
    Bar_L_F13 Bar_L_F14 Bar_L_F15 Bar_L_F16
)

SAMPLE=${SAMPLES[$LSB_JOBINDEX-1]}
[[ -z "$SAMPLE" ]] && echo "Error: no sample for index ${LSB_JOBINDEX}" && exit 1
echo "Sample: ${SAMPLE}"

READ1=${TRIMMED}/Bar_L/${SAMPLE}_R1_paired.fastq.gz
READ2=${TRIMMED}/Bar_L/${SAMPLE}_R2_paired.fastq.gz
[[ ! -f "$READ1" ]] && echo "Error: R1 not found: $READ1" && exit 1
[[ ! -f "$READ2" ]] && echo "Error: R2 not found: $READ2" && exit 1

OUTDIR=${ANGSD_BAM_DIR}/Bar_L
mkdir -p "$OUTDIR"
TMPDIR=${OUTDIR}/tmp_${SAMPLE}
mkdir -p "$TMPDIR"

PU=$(zcat "$READ1" | head -1 | cut -d: -f3,4 --output-delimiter='.')
[[ -z "$PU" ]] && PU="unknown"
RG="@RG\\tID:${SAMPLE}\\tSM:${SAMPLE}\\tLB:${SAMPLE}\\tPL:ILLUMINA\\tPU:${PU}"

module load apptainer

apptainer exec \
    --bind ${TRIMMED}:${TRIMMED},${REF_DIR}:${REF_DIR},${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} \
    $BWAMEM2_SIF \
    bwa-mem2 mem -t 6 -R "${RG}" "$REFERENCE" "$READ1" "$READ2" \
| apptainer exec --bind ${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} $SAMTOOLS_SIF \
    samtools fixmate -m -u - - \
| apptainer exec --bind ${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} $SAMTOOLS_SIF \
    samtools sort -@ 2 -T "${TMPDIR}/${SAMPLE}" -u - \
| apptainer exec --bind ${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} $SAMTOOLS_SIF \
    samtools markdup -S -T "${TMPDIR}/${SAMPLE}_markdup" - "${OUTDIR}/${SAMPLE}.sorted.markdup.bam"

[[ $? -ne 0 ]] && echo "Error: pipeline failed" && rm -rf "$TMPDIR" && exit 1

apptainer exec --bind ${OUTDIR}:${OUTDIR} $SAMTOOLS_SIF \
    samtools index "${OUTDIR}/${SAMPLE}.sorted.markdup.bam"
apptainer exec --bind ${OUTDIR}:${OUTDIR} $SAMTOOLS_SIF \
    samtools flagstat "${OUTDIR}/${SAMPLE}.sorted.markdup.bam" > "${OUTDIR}/${SAMPLE}.flagstat.txt"

echo "BAM: $(ls -lh "${OUTDIR}/${SAMPLE}.sorted.markdup.bam" | awk '{print $5}')"
cat "${OUTDIR}/${SAMPLE}.flagstat.txt"
rm -rf "$TMPDIR"
echo "Done: ${SAMPLE}"; date
