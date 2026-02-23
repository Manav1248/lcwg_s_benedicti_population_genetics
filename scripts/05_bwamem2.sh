#!/bin/bash
# 05_bwamem2.sh - align + markdup (flag only, for ANGSD)
# bwa-mem2 -> fixmate -> sort -> markdup -> index

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/05_bwamem2.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/05_bwamem2.config"

ENTRY=$(get_sample_entry)
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")
echo "Sample: ${NAME} (${SUBDIR})"

READ1=${TRIMMED}/${SUBDIR}/${NAME}_R1_paired.fastq.gz
READ2=${TRIMMED}/${SUBDIR}/${NAME}_R2_paired.fastq.gz
[[ ! -f "$READ1" ]] && echo "Error: R1 not found: $READ1" && exit 1
[[ ! -f "$READ2" ]] && echo "Error: R2 not found: $READ2" && exit 1
[[ ! -f "${REFERENCE}.bwt.2bit.64" ]] && echo "Error: bwa index missing" && exit 1

OUTDIR=${ALIGN_DIR}/${SUBDIR}
mkdir -p "$OUTDIR"
REF_DIR=$(dirname "$REFERENCE")
TMPDIR=${OUTDIR}/tmp_${NAME}
mkdir -p "$TMPDIR"

# read group from fastq header
# turns HFLOWCELL:1 into HFLOWCELL.1 for PU (platform unit)
PU=$(zcat "$READ1" | head -1 | cut -d: -f3,4 --output-delimiter='.')
[[ -z "$PU" ]] && PU="unknown" # fallback to "unknown" if PU is empty
RG="@RG\\tID:${NAME}\\tSM:${NAME}\\tLB:${NAME}\\tPL:ILLUMINA\\tPU:${PU}"

module load apptainer

BWA_THREADS=$((JOB5_CPUS - 2))

# align -> fixmate -> sort -> markdup (flag only, no -r)
apptainer exec \
    --bind ${TRIMMED}:${TRIMMED},${REF_DIR}:${REF_DIR},${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} \
    $BWAMEM2_SIF \
    bwa-mem2 mem -t ${BWA_THREADS} -R "${RG}" "$REFERENCE" "$READ1" "$READ2" \
| apptainer exec --bind ${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} $SAMTOOLS_SIF \
    samtools fixmate -m -u - - \
| apptainer exec --bind ${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} $SAMTOOLS_SIF \
    samtools sort -@ 2 -T "${TMPDIR}/${NAME}" -u - \
| apptainer exec --bind ${OUTDIR}:${OUTDIR},${TMPDIR}:${TMPDIR} $SAMTOOLS_SIF \
    samtools markdup -S -T "${TMPDIR}/${NAME}_markdup" - "${OUTDIR}/${NAME}.sorted.markdup.bam"

[[ $? -ne 0 ]] && echo "Error: pipeline failed" && rm -rf "$TMPDIR" && exit 1

# index + flagstat
apptainer exec --bind ${OUTDIR}:${OUTDIR} $SAMTOOLS_SIF \
    samtools index "${OUTDIR}/${NAME}.sorted.markdup.bam"
apptainer exec --bind ${OUTDIR}:${OUTDIR} $SAMTOOLS_SIF \
    samtools flagstat "${OUTDIR}/${NAME}.sorted.markdup.bam" > "${OUTDIR}/${NAME}.flagstat.txt"

cat "${OUTDIR}/${NAME}.flagstat.txt"
rm -rf "$TMPDIR"
echo "Done: ${NAME}"; date
