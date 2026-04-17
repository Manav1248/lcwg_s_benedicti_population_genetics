#!/bin/bash
# 16_fst_fast.sh - pairwise FST using per-chromosome SAFs
# array job: indexed by pair number in pop_pairs.txt
# does 2D-SFS, fst index, and fst stats all per-chromosome
# avoids merged SAFs entirely

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
SAF_OUT=${WORKING_DIR}/14_ANGSD_SAF
FST_OUT=${WORKING_DIR}/16_FST
PAIRS_FILE=${FST_OUT}/pop_pairs.txt
ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt

[[ ! -f "$PAIRS_FILE" ]] && echo "Error: pairs file not found" && exit 1
[[ ! -f "$CHROM_LIST" ]] && echo "Error: chrom list not found" && exit 1

PAIR_LINE=$(sed -n "${LSB_JOBINDEX}p" "$PAIRS_FILE")
POP1=$(echo "$PAIR_LINE" | cut -d' ' -f1)
POP2=$(echo "$PAIR_LINE" | cut -d' ' -f2)

[[ -z "$POP1" || -z "$POP2" ]] && echo "Error: no pair for index ${LSB_JOBINDEX}" && exit 1

OUTDIR=${FST_OUT}/pairwise
TMPDIR=${OUTDIR}/tmp_${POP1}_${POP2}
mkdir -p "$OUTDIR" "$TMPDIR"

echo "FST: ${POP1} vs ${POP2} (job ${LSB_JOBINDEX})"

# --- Pre-flight: verify all SAFs exist and are non-empty ---
echo "Checking SAF files..."
while IFS= read -r CHR; do
    SAF1=${SAF_OUT}/${POP1}/per_chrom/${POP1}.${CHR}.saf.idx
    SAF2=${SAF_OUT}/${POP2}/per_chrom/${POP2}.${CHR}.saf.idx
    for SAF in "$SAF1" "$SAF2"; do
        if [[ ! -f "$SAF" ]]; then
            echo "Error: SAF not found: $SAF"
            exit 1
        fi
        if [[ ! -s "$SAF" ]]; then
            echo "Error: SAF is empty (0 bytes): $SAF"
            exit 1
        fi
    done
done < "$CHROM_LIST"
echo "All SAFs verified."

module load apptainer

ANGSD_CMD="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $ANGSD_SIF"

# --- Per-chromosome: 2D-SFS + fst index ---
FST_IDX_FILES=""
while IFS= read -r CHR; do
    SAF1=${SAF_OUT}/${POP1}/per_chrom/${POP1}.${CHR}.saf.idx
    SAF2=${SAF_OUT}/${POP2}/per_chrom/${POP2}.${CHR}.saf.idx

    echo "  ${CHR}: estimating 2D-SFS..."
    $ANGSD_CMD realSFS $SAF1 $SAF2 \
        -fold 1 \
        -P 8 \
        -maxIter 200 \
        -tole 1e-6 \
        > ${TMPDIR}/${CHR}.2dsfs

    if [[ $? -ne 0 || ! -s ${TMPDIR}/${CHR}.2dsfs ]]; then
        echo "Error: 2D-SFS failed or empty for ${CHR}"
        exit 1
    fi

    echo "  ${CHR}: building fst index..."
    $ANGSD_CMD realSFS fst index $SAF1 $SAF2 \
        -sfs ${TMPDIR}/${CHR}.2dsfs \
        -fold 1 \
        -fstout ${TMPDIR}/${CHR}

    if [[ $? -ne 0 || ! -f ${TMPDIR}/${CHR}.fst.idx ]]; then
        echo "Error: fst index failed for ${CHR}"
        exit 1
    fi

    FST_IDX_FILES="${FST_IDX_FILES} ${TMPDIR}/${CHR}.fst.idx"
done < "$CHROM_LIST"

# --- Global FST across all chromosomes ---
echo "Estimating global FST..."
$ANGSD_CMD realSFS fst stats $FST_IDX_FILES \
    > ${OUTDIR}/${POP1}.${POP2}.global_fst.txt

if [[ $? -ne 0 || ! -s ${OUTDIR}/${POP1}.${POP2}.global_fst.txt ]]; then
    echo "Error: global fst stats failed"
    exit 1
fi

echo "Global FST (${POP1} vs ${POP2}):"
cat ${OUTDIR}/${POP1}.${POP2}.global_fst.txt

# --- Windowed FST across all chromosomes ---
echo "Estimating windowed FST..."
$ANGSD_CMD realSFS fst stats2 $FST_IDX_FILES \
    -win 50000 -step 25000 -type 2 \
    > ${OUTDIR}/${POP1}.${POP2}.windowed_fst.txt

if [[ $? -ne 0 || ! -s ${OUTDIR}/${POP1}.${POP2}.windowed_fst.txt ]]; then
    echo "Error: windowed fst stats failed"
    exit 1
fi

# --- Save summed 2D-SFS for reference ---
python3 -c "
import glob
files = sorted(glob.glob('${TMPDIR}/*.2dsfs'))
total = None
for f in files:
    with open(f) as fh:
        vals = [float(x) for x in fh.read().strip().split()]
        if total is None:
            total = vals
        else:
            total = [a+b for a,b in zip(total, vals)]
print(' '.join(str(v) for v in total))
" > ${OUTDIR}/${POP1}.${POP2}.2dsfs

# --- Cleanup ---
rm -rf "$TMPDIR"
echo "Done"; date
