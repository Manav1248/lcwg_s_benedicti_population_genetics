#!/bin/bash
# 03_fastqc_before.sh - FastQC on raw reads

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/03_fastqc_before.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/03_fastqc_before.config"

ENTRY=$(get_sample_entry)
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")

READ1=${READS_BASE}/${ENTRY}_R1.fastq
READ2=${READS_BASE}/${ENTRY}_R2.fastq
[[ ! -f "$READ1" ]] && echo "Error: R1 not found: $READ1" && exit 1
[[ ! -f "$READ2" ]] && echo "Error: R2 not found: $READ2" && exit 1

OUTDIR=${FASTQC_BEFORE}/${SUBDIR}/${NAME}
mkdir -p "$OUTDIR"

module load apptainer
apptainer exec \
    --bind ${OUTDIR}:${OUTDIR},${FASTQC_BEFORE}:${FASTQC_BEFORE},${READS_BASE}:${READS_BASE} \
    $FASTQC_SIF \
    fastqc --threads $JOB3_CPUS -o $OUTDIR $READ1 $READ2

cd ${OUTDIR} && ls *.html 1>/dev/null 2>&1 && mv *.html ${FASTQC_B_HTML}/

echo "Done: ${NAME}"; date

# multiqc if all samples finished
EXPECTED_ZIPS=$(( $(wc -l < "$XFILE") * 2 ))
COMPLETED_ZIPS=$(find ${FASTQC_BEFORE} -name "*.zip" 2>/dev/null | wc -l)
if [[ $COMPLETED_ZIPS -ge $EXPECTED_ZIPS ]]; then
    echo "All done ($COMPLETED_ZIPS/$EXPECTED_ZIPS). Running MultiQC..."
    apptainer exec --bind ${FASTQC_BEFORE}:${FASTQC_BEFORE} $MULTIQC_SIF \
        multiqc ${FASTQC_BEFORE} -o ${FASTQC_BEFORE} -n multiqc_before_trim --force
fi
date
