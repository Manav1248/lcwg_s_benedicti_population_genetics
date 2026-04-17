#!/bin/bash
#BSUB -J streb_catchup
#BSUB -n 8
#BSUB -W 04:00
#BSUB -R "span[hosts=1] rusage[mem=12GB]"
#BSUB -o logs/catchup_%J.out
#BSUB -e logs/catchup_%J.err
#
# streb_catchup.sh - one-shot pipeline for 2 recovered samples + 1 removal
#
# Actions:
#   1. Remove Bar_T1_L (U16) from all pipeline directories -> unused/
#   2. Add BAR523L_I -> Bar_L_F16 (female, L type)
#   3. Add FL_M9_4  -> FL_P_F06 (female, P type)
#   Both new samples run: gunzip+rename -> FastQC before -> Trimmomatic -> FastQC after
#
# Also updates full_sample_list.txt automatically (removes U16, adds F16 and F06)
# After this script completes, samples are ready for BWA via the existing launchers.
#
# Usage:
#   mkdir -p logs && bsub < streb_catchup.sh

pwd; hostname; date

# ---- Paths ----
PROJECT=/share/ivirus/dhermos/zakas_project
READS_BASE=${PROJECT}/reads
TRIMMED_SRC=${PROJECT}/trimmed
UNUSED=${PROJECT}/reads/unused
SAMPLE_LIST=${PROJECT}/scripts/full_sample_list.txt

FASTQC_BEFORE=${PROJECT}/03_FASTQC_BEFORE
FASTQC_AFTER=${PROJECT}/06_FASTQC_AFTER
TRIM_DIR=${PROJECT}/04_TRIMMOMATIC
TRIMMED_OUT=${TRIM_DIR}/trimmed_reads
UNPAIRED_OUT=${TRIM_DIR}/unpaired_reads
BWA_ANGSD=${PROJECT}/05_BWA_MEM2
BWA_GATK=${PROJECT}/05_BWA_MEM2/gatk_downstream

# Containers
CONT=/rs1/shares/brc/admin/containers/images
FASTQC_SIF=$CONT/quay.io_biocontainers_fastqc:0.12.1--hdfd78af_0.sif
TRIMMOMATIC_SIF=$CONT/quay.io_biocontainers_trimmomatic:0.40--hdfd78af_0.sif
MULTIQC_SIF=$CONT/quay.io_biocontainers_multiqc:1.23--pyhdfd78af_0.sif

# Databases
ADAPTERS=/rs1/shares/brc/admin/databases/adapters/TruSeq3-PE-2.fa

# Trimmomatic parameters (match 04_trimmomatic.config)
TRIM_ILLUMINACLIP="2:30:10"
TRIM_SLIDINGWINDOW="4:20"
TRIM_MINLEN="50"

# Source files for recovered reads
BAR_R1_SRC=${TRIMMED_SRC}/raw_reads/BAR523L_I_S82_L003_R1_001_trimmedF.fastq.gz
BAR_R2_SRC=${TRIMMED_SRC}/unused/BAR523L_I_S82_L003_R2_001_trimmedF.fastq.gz
FL_R1_SRC=${TRIMMED_SRC}/unused/FL_M9_4_S54_L003_R1_001_trimmedF.fastq.gz
FL_R2_SRC=${TRIMMED_SRC}/raw_reads/FL_M9_4_S54_L003_R2_001_trimmedF.fastq.gz

module load apptainer

# STEP 0: Verify all source files exist
echo "Step 0: Pre-flight checks"
MISSING=0
for f in "$BAR_R1_SRC" "$BAR_R2_SRC" "$FL_R1_SRC" "$FL_R2_SRC"; do
    if [[ ! -f "$f" ]]; then
        echo "  MISSING: $f"
        MISSING=$((MISSING + 1))
    else
        echo "  OK: $(basename $f)"
    fi
done
if [[ $MISSING -gt 0 ]]; then
    echo "ERROR: ${MISSING} source file(s) missing. Aborting."
    exit 1
fi
echo ""

# STEP 1: Remove Bar_T1_L (Bar_L_U16) from everywhere -> unused/
echo "Step 1: Remove Bar_T1_L (Bar_L_U16)"
mkdir -p "${UNUSED}"

# Reads
for f in ${READS_BASE}/Bar_L/Bar_L_U16_R*.fastq; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done

# FastQC before
if [[ -d "${FASTQC_BEFORE}/Bar_L/Bar_L_U16" ]]; then
    mv "${FASTQC_BEFORE}/Bar_L/Bar_L_U16" "${UNUSED}/Bar_L_U16_fastqc_before"
    echo "  Moved: FastQC before dir -> unused/"
fi
for f in ${FASTQC_BEFORE}/htmls/Bar_L_U16_*.html; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done

# FastQC after
if [[ -d "${FASTQC_AFTER}/Bar_L/Bar_L_U16" ]]; then
    mv "${FASTQC_AFTER}/Bar_L/Bar_L_U16" "${UNUSED}/Bar_L_U16_fastqc_after"
    echo "  Moved: FastQC after dir -> unused/"
fi
for f in ${FASTQC_AFTER}/htmls/Bar_L_U16_*.html; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done

# Trimmomatic outputs
for f in ${TRIMMED_OUT}/Bar_L/Bar_L_U16_*.fastq.gz; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done
for f in ${UNPAIRED_OUT}/Bar_L/Bar_L_U16_*.fastq.gz; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done

# BWA outputs (ANGSD)
for f in ${BWA_ANGSD}/Bar_L/Bar_L_U16.*; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done

# BWA outputs (GATK)
for f in ${BWA_GATK}/Bar_L/Bar_L_U16.*; do
    [[ -f "$f" ]] && mv "$f" "${UNUSED}/" && echo "  Moved: $(basename $f) -> unused/"
done

echo "  Bar_T1_L cleanup complete."
echo ""

# STEP 2: Gunzip + rename recovered samples into reads/
echo "Step 2: Gunzip + rename recovered samples"

# BAR523L_I -> Bar_L_F16
echo "  BAR523L_I -> Bar_L/Bar_L_F16"
zcat "$BAR_R1_SRC" > "${READS_BASE}/Bar_L/Bar_L_F16_R1.fastq"
zcat "$BAR_R2_SRC" > "${READS_BASE}/Bar_L/Bar_L_F16_R2.fastq"
echo "    R1: $(wc -l < ${READS_BASE}/Bar_L/Bar_L_F16_R1.fastq) lines"
echo "    R2: $(wc -l < ${READS_BASE}/Bar_L/Bar_L_F16_R2.fastq) lines"

# FL_M9_4 -> FL_P_F06
echo "  FL_M9_4 -> FL/FL_P_F06"
zcat "$FL_R1_SRC" > "${READS_BASE}/FL/FL_P_F06_R1.fastq"
zcat "$FL_R2_SRC" > "${READS_BASE}/FL/FL_P_F06_R2.fastq"
echo "    R1: $(wc -l < ${READS_BASE}/FL/FL_P_F06_R1.fastq) lines"
echo "    R2: $(wc -l < ${READS_BASE}/FL/FL_P_F06_R2.fastq) lines"
echo ""

# STEP 3: FastQC before trim
echo "Step 3: FastQC before trim"

for SAMPLE in "Bar_L/Bar_L_F16" "FL/FL_P_F06"; do
    SUBDIR=$(dirname "$SAMPLE")
    NAME=$(basename "$SAMPLE")
    OUTDIR=${FASTQC_BEFORE}/${SUBDIR}/${NAME}
    mkdir -p "$OUTDIR"

    echo "  Running FastQC (before) on ${NAME}..."
    apptainer exec \
        --bind ${OUTDIR}:${OUTDIR},${FASTQC_BEFORE}:${FASTQC_BEFORE},${READS_BASE}:${READS_BASE} \
        $FASTQC_SIF \
        fastqc --threads 4 -o $OUTDIR \
        ${READS_BASE}/${SAMPLE}_R1.fastq \
        ${READS_BASE}/${SAMPLE}_R2.fastq

    # Move HTMLs
    cd ${OUTDIR}
    if ls *.html 1>/dev/null 2>&1; then
        mv *.html ${FASTQC_BEFORE}/htmls/
        echo "    HTMLs moved"
    fi
done
echo ""

# STEP 4: Trimmomatic
echo "Step 4: Trimmomatic"
ADAPTER_DIR=$(dirname $ADAPTERS)

for SAMPLE in "Bar_L/Bar_L_F16" "FL/FL_P_F06"; do
    SUBDIR=$(dirname "$SAMPLE")
    NAME=$(basename "$SAMPLE")
    mkdir -p "${TRIMMED_OUT}/${SUBDIR}" "${UNPAIRED_OUT}/${SUBDIR}"

    echo "  Trimming ${NAME}..."
    apptainer exec \
        --bind ${READS_BASE}:${READS_BASE},${TRIM_DIR}:${TRIM_DIR},${ADAPTER_DIR}:${ADAPTER_DIR} \
        --env _JAVA_OPTIONS="-Xmx6G" \
        $TRIMMOMATIC_SIF \
        trimmomatic PE -phred33 -threads 8 \
        ${READS_BASE}/${SAMPLE}_R1.fastq \
        ${READS_BASE}/${SAMPLE}_R2.fastq \
        ${TRIMMED_OUT}/${SUBDIR}/${NAME}_R1_paired.fastq.gz \
        ${UNPAIRED_OUT}/${SUBDIR}/${NAME}_R1_unpaired.fastq.gz \
        ${TRIMMED_OUT}/${SUBDIR}/${NAME}_R2_paired.fastq.gz \
        ${UNPAIRED_OUT}/${SUBDIR}/${NAME}_R2_unpaired.fastq.gz \
        ILLUMINACLIP:${ADAPTERS}:${TRIM_ILLUMINACLIP} \
        SLIDINGWINDOW:${TRIM_SLIDINGWINDOW} \
        MINLEN:${TRIM_MINLEN}

    echo "    Done: ${NAME}"
done
echo ""

# STEP 5: FastQC after trim
echo "Step 5: FastQC after trim"

for SAMPLE in "Bar_L/Bar_L_F16" "FL/FL_P_F06"; do
    SUBDIR=$(dirname "$SAMPLE")
    NAME=$(basename "$SAMPLE")
    OUTDIR=${FASTQC_AFTER}/${SUBDIR}/${NAME}
    mkdir -p "$OUTDIR" "${FASTQC_AFTER}/htmls"

    echo "  Running FastQC (after) on ${NAME}..."
    apptainer exec \
        --bind ${OUTDIR}:${OUTDIR},${FASTQC_AFTER}:${FASTQC_AFTER},${TRIMMED_OUT}:${TRIMMED_OUT} \
        $FASTQC_SIF \
        fastqc --threads 4 -o $OUTDIR \
        ${TRIMMED_OUT}/${SUBDIR}/${NAME}_R1_paired.fastq.gz \
        ${TRIMMED_OUT}/${SUBDIR}/${NAME}_R2_paired.fastq.gz

    # Move HTMLs
    cd ${OUTDIR}
    if ls *.html 1>/dev/null 2>&1; then
        mv *.html ${FASTQC_AFTER}/htmls/
        echo "    HTMLs moved"
    fi
done
echo ""

# STEP 6: Refresh MultiQC reports
echo "Step 6: MultiQC refresh"

echo "  Before-trim report..."
apptainer exec \
    --bind ${FASTQC_BEFORE}:${FASTQC_BEFORE} \
    $MULTIQC_SIF \
    multiqc ${FASTQC_BEFORE} -o ${FASTQC_BEFORE} -n multiqc_before_trim --force

echo "  After-trim report..."
apptainer exec \
    --bind ${FASTQC_AFTER}:${FASTQC_AFTER} \
    $MULTIQC_SIF \
    multiqc ${FASTQC_AFTER} -o ${FASTQC_AFTER} -n multiqc_after_trim --force

echo ""

# STEP 7: Update full_sample_list.txt
echo "Step 7: Update sample list"

if [[ ! -f "$SAMPLE_LIST" ]]; then
    echo "  WARNING: ${SAMPLE_LIST} not found. Skipping update."
    echo "  You will need to manually update your sample list."
else
    # Remove Bar_L_U16 if present
    if grep -q "Bar_L/Bar_L_U16" "$SAMPLE_LIST"; then
        sed -i '/Bar_L\/Bar_L_U16/d' "$SAMPLE_LIST"
        echo "  Removed: Bar_L/Bar_L_U16"
    else
        echo "  Bar_L/Bar_L_U16 not in list (already removed or never added)"
    fi

    # Add Bar_L_F16 if not already there
    if grep -q "Bar_L/Bar_L_F16" "$SAMPLE_LIST"; then
        echo "  Bar_L/Bar_L_F16 already in list"
    else
        echo "Bar_L/Bar_L_F16" >> "$SAMPLE_LIST"
        echo "  Added: Bar_L/Bar_L_F16"
    fi

    # Add FL_P_F06 if not already there
    if grep -q "FL/FL_P_F06" "$SAMPLE_LIST"; then
        echo "  FL/FL_P_F06 already in list"
    else
        echo "FL/FL_P_F06" >> "$SAMPLE_LIST"
        echo "  Added: FL/FL_P_F06"
    fi

    # Sort for consistency
    sort -o "$SAMPLE_LIST" "$SAMPLE_LIST"
    echo "  Sorted. Total samples: $(wc -l < "$SAMPLE_LIST")"
fi
echo ""

# STEP 8: Verification
echo "Step 8: Verification"
echo ""
echo "REMOVED:"
echo "  Bar_T1_L (Bar_L_U16) -> unused/"
echo ""
echo "ADDED:"
echo "  BAR523L_I -> Bar_L/Bar_L_F16 (female, L)"
echo "  FL_M9_4   -> FL/FL_P_F06 (female, P)"
echo ""
echo "COUNTS:"
echo "  Bar_L reads: $(ls ${READS_BASE}/Bar_L/*_R1.fastq 2>/dev/null | wc -l) samples"
echo "  FL reads:    $(ls ${READS_BASE}/FL/*_R1.fastq 2>/dev/null | wc -l) samples"
echo "  Sample list: $(wc -l < "$SAMPLE_LIST" 2>/dev/null) total"
echo ""

# Verify new files exist at each stage
echo "FILE CHECK:"
for SAMPLE in "Bar_L/Bar_L_F16" "FL/FL_P_F06"; do
    NAME=$(basename "$SAMPLE")
    SUBDIR=$(dirname "$SAMPLE")
    echo "  ${NAME}:"
    [[ -f "${READS_BASE}/${SAMPLE}_R1.fastq" ]]                && echo "    [OK] reads" || echo "    [MISSING] reads MISSING"
    [[ -f "${TRIMMED_OUT}/${SUBDIR}/${NAME}_R1_paired.fastq.gz" ]] && echo "    [OK] trimmed" || echo "    [MISSING] trimmed MISSING"
    ZIPS=$(find ${FASTQC_BEFORE}/${SUBDIR}/${NAME} -name "*.zip" 2>/dev/null | wc -l)
    [[ $ZIPS -ge 2 ]]                                          && echo "    [OK] fastqc before ($ZIPS zips)" || echo "    [MISSING] fastqc before MISSING"
    ZIPS=$(find ${FASTQC_AFTER}/${SUBDIR}/${NAME} -name "*.zip" 2>/dev/null | wc -l)
    [[ $ZIPS -ge 2 ]]                                          && echo "    [OK] fastqc after ($ZIPS zips)" || echo "    [MISSING] fastqc after MISSING"
done

echo ""
echo "Bar_L_U16 should be gone:"
REMAINING=$(find ${PROJECT} -name "*Bar_L_U16*" ! -path "*/unused/*" 2>/dev/null | wc -l)
if [[ $REMAINING -eq 0 ]]; then
    echo "  [OK] No Bar_L_U16 files outside unused/"
else
    echo "  [MISSING] ${REMAINING} file(s) still found:"
    find ${PROJECT} -name "*Bar_L_U16*" ! -path "*/unused/*" 2>/dev/null | sed 's/^/    /'
fi

echo ""
echo "Catchup pipeline complete. Samples ready for BWA via existing launchers."
date
