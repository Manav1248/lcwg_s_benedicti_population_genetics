#!/bin/bash
# 07_bam_qc.sh - BAM-level QC: Qualimap bamqc + mosdepth on ANGSD and GATK BAMs

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/07_bam_qc.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/07_bam_qc.config"

ENTRY=$(get_sample_entry)
NAME=$(basename "$ENTRY")
SUBDIR=$(dirname "$ENTRY")
echo "Processing sample: ${NAME} (population: ${SUBDIR})"

# input BAMs...
ANGSD_BAM=${ANGSD_BAM_DIR}/${SUBDIR}/${NAME}.sorted.markdup.bam
GATK_BAM=${GATK_BAM_DIR}/${SUBDIR}/${NAME}.sorted.dedup.bam

[[ ! -f "$ANGSD_BAM" ]] && echo "Error: ANGSD BAM not found: $ANGSD_BAM" && exit 1
[[ ! -f "$GATK_BAM" ]]  && echo "Error: GATK BAM not found: $GATK_BAM" && exit 1

# output directories...
ANGSD_QUALI_OUT=${QC_ANGSD_QUALIMAP}/${SUBDIR}/${NAME}
ANGSD_MOS_OUT=${QC_ANGSD_MOSDEPTH}/${SUBDIR}
GATK_QUALI_OUT=${QC_GATK_QUALIMAP}/${SUBDIR}/${NAME}
GATK_MOS_OUT=${QC_GATK_MOSDEPTH}/${SUBDIR}

mkdir -p "$ANGSD_QUALI_OUT" "$ANGSD_MOS_OUT" "$GATK_QUALI_OUT" "$GATK_MOS_OUT"

module load apptainer

# 1. Qualimap bamqc — ANGSD BAM (duplicates flagged)
echo "[$(date)] Running Qualimap on ANGSD BAM..."
apptainer exec \
    --bind ${ANGSD_BAM_DIR}:${ANGSD_BAM_DIR},${ANGSD_QUALI_OUT}:${ANGSD_QUALI_OUT} \
    $QUALIMAP_SIF \
    qualimap bamqc \
        -bam $ANGSD_BAM \
        -outdir $ANGSD_QUALI_OUT \
        -nt $QUALIMAP_THREADS \
        --java-mem-size=${QUALIMAP_JAVA_MEM}

# 2. mosdepth — ANGSD BAM
echo "[$(date)] Running mosdepth on ANGSD BAM..."
apptainer exec \
    --bind ${ANGSD_BAM_DIR}:${ANGSD_BAM_DIR},${ANGSD_MOS_OUT}:${ANGSD_MOS_OUT} \
    $MOSDEPTH_SIF \
    mosdepth \
        --by $MOSDEPTH_WINDOW \
        --no-per-base \
        --threads $MOSDEPTH_THREADS \
        ${ANGSD_MOS_OUT}/${NAME}.angsd \
        $ANGSD_BAM

# 3. Qualimap bamqc — GATK BAM (duplicates removed)
echo "[$(date)] Running Qualimap on GATK BAM..."
apptainer exec \
    --bind ${GATK_BAM_DIR}:${GATK_BAM_DIR},${GATK_QUALI_OUT}:${GATK_QUALI_OUT} \
    $QUALIMAP_SIF \
    qualimap bamqc \
        -bam $GATK_BAM \
        -outdir $GATK_QUALI_OUT \
        -nt $QUALIMAP_THREADS \
        --java-mem-size=${QUALIMAP_JAVA_MEM}

# 4. mosdepth — GATK BAM
echo "[$(date)] Running mosdepth on GATK BAM..."
apptainer exec \
    --bind ${GATK_BAM_DIR}:${GATK_BAM_DIR},${GATK_MOS_OUT}:${GATK_MOS_OUT} \
    $MOSDEPTH_SIF \
    mosdepth \
        --by $MOSDEPTH_WINDOW \
        --no-per-base \
        --threads $MOSDEPTH_THREADS \
        ${GATK_MOS_OUT}/${NAME}.gatk \
        $GATK_BAM

echo "Done: ${NAME}"; date
