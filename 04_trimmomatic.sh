#!/bin/bash
# 04_trimmomatic.sh - trim + post-trim fastqc appended

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/04_trimmomatic.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/04_trimmomatic.config"

ENTRY=$(get_sample_entry)
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")

READ1=${READS_BASE}/${ENTRY}_R1.fastq
READ2=${READS_BASE}/${ENTRY}_R2.fastq
[[ ! -f "$READ1" ]] && echo "Error: R1 not found: $READ1" && exit 1
[[ ! -f "$READ2" ]] && echo "Error: R2 not found: $READ2" && exit 1

TRIM_OUT=${TRIMMED}/${SUBDIR}
UNPAIR_OUT=${UNPAIRED}/${SUBDIR}
mkdir -p "$TRIM_OUT" "$UNPAIR_OUT"

ADAPTER_DIR=$(dirname $ADAPTERS)

module load apptainer
apptainer exec \
    --bind ${READS_BASE}:${READS_BASE},${TRIM_DIR}:${TRIM_DIR},${ADAPTER_DIR}:${ADAPTER_DIR} \
    --env _JAVA_OPTIONS="-Xmx6G" \
    $TRIMMOMATIC_SIF \
    trimmomatic PE -phred33 -threads $JOB4_CPUS \
    $READ1 $READ2 \
    ${TRIM_OUT}/${NAME}_R1_paired.fastq.gz ${UNPAIR_OUT}/${NAME}_R1_unpaired.fastq.gz \
    ${TRIM_OUT}/${NAME}_R2_paired.fastq.gz ${UNPAIR_OUT}/${NAME}_R2_unpaired.fastq.gz \
    ILLUMINACLIP:${ADAPTERS}:${TRIM_ILLUMINACLIP} \
    SLIDINGWINDOW:${TRIM_SLIDINGWINDOW} \
    MINLEN:${TRIM_MINLEN} \
    ${TRIM_HEADCROP:+HEADCROP:${TRIM_HEADCROP}}

echo "Trimmed: ${NAME}"; date

# post-trim fastqc
FASTQC_OUT=${WORKING_DIR}/06_FASTQC_AFTER/${SUBDIR}/${NAME}
FASTQC_A_HTML=${WORKING_DIR}/06_FASTQC_AFTER/htmls
mkdir -p "$FASTQC_OUT" "$FASTQC_A_HTML"

apptainer exec \
    --bind ${FASTQC_OUT}:${FASTQC_OUT},${WORKING_DIR}:${WORKING_DIR},${TRIMMED}:${TRIMMED} \
    $FASTQC_SIF \
    fastqc --threads $JOB4_CPUS -o $FASTQC_OUT \
    ${TRIM_OUT}/${NAME}_R1_paired.fastq.gz ${TRIM_OUT}/${NAME}_R2_paired.fastq.gz

cd ${FASTQC_OUT} && ls *.html 1>/dev/null 2>&1 && mv *.html ${FASTQC_A_HTML}/

# multiqc if all done
FASTQC_AFTER_BASE=${WORKING_DIR}/06_FASTQC_AFTER
EXPECTED_ZIPS=$(( $(wc -l < "$XFILE") * 2 ))
COMPLETED_ZIPS=$(find ${FASTQC_AFTER_BASE} -name "*.zip" 2>/dev/null | wc -l)
if [[ $COMPLETED_ZIPS -ge $EXPECTED_ZIPS ]]; then
    apptainer exec --bind ${FASTQC_AFTER_BASE}:${FASTQC_AFTER_BASE} $MULTIQC_SIF \
        multiqc ${FASTQC_AFTER_BASE} -o ${FASTQC_AFTER_BASE} -n multiqc_after_trim --force
fi
date
