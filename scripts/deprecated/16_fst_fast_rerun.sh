#!/bin/bash
# re-run of 16_fst_fast.sh with tighter convergence and resume-from-tmp support

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
SAF_OUT=${WORKING_DIR}/14_ANGSD_SAF
FST_OUT=${WORKING_DIR}/16_FST
PAIRS_FILE=${FST_OUT}/pop_pairs.txt
ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt

PAIR_LINE=$(sed -n "${LSB_JOBINDEX}p" "$PAIRS_FILE")
POP1=$(echo "$PAIR_LINE" | cut -d' ' -f1)
POP2=$(echo "$PAIR_LINE" | cut -d' ' -f2)

OUTDIR=${FST_OUT}/pairwise
TMPDIR=${OUTDIR}/tmp_${POP1}_${POP2}
mkdir -p "$OUTDIR" "$TMPDIR"

echo "FST: ${POP1} vs ${POP2} (job ${LSB_JOBINDEX})"

# skip if already done
if [[ -s "${OUTDIR}/${POP1}.${POP2}.global_fst.txt" && -s "${OUTDIR}/${POP1}.${POP2}.windowed_fst.txt" ]]; then
    echo "Already complete, skipping."
    exit 0
fi

module load apptainer
ANGSD_CMD="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $ANGSD_SIF"

# per-chrom loop: skip chromosomes that already have fst.idx, redo partial ones
FST_IDX_FILES=""
while IFS= read -r CHR; do
    SAF1=${SAF_OUT}/${POP1}/per_chrom/${POP1}.${CHR}.saf.idx
    SAF2=${SAF_OUT}/${POP2}/per_chrom/${POP2}.${CHR}.saf.idx

    # skip if fst.idx exists and is non-empty (Ch was fully done)
    if [[ -s ${TMPDIR}/${CHR}.fst.idx && -s ${TMPDIR}/${CHR}.fst.gz ]]; then
        echo "  ${CHR}: already done, skipping"
        FST_IDX_FILES="${FST_IDX_FILES} ${TMPDIR}/${CHR}.fst.idx"
        continue
    fi

    # clean up any partial output for this chrom
    rm -f ${TMPDIR}/${CHR}.2dsfs ${TMPDIR}/${CHR}.fst.idx ${TMPDIR}/${CHR}.fst.gz

    echo "  ${CHR}: estimating 2D-SFS..."
    $ANGSD_CMD realSFS $SAF1 $SAF2 \
        -fold 1 \
        -P 8 \
        -maxIter 100 \
        -tole 1e-6 \
        > ${TMPDIR}/${CHR}.2dsfs

    if [[ $? -ne 0 || ! -s ${TMPDIR}/${CHR}.2dsfs ]]; then
        echo "Error: 2D-SFS failed for ${CHR}"
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

# global FST
echo "Estimating global FST..."
$ANGSD_CMD realSFS fst stats $FST_IDX_FILES \
    > ${OUTDIR}/${POP1}.${POP2}.global_fst.txt
[[ $? -ne 0 || ! -s ${OUTDIR}/${POP1}.${POP2}.global_fst.txt ]] && echo "Error: global fst stats failed" && exit 1

echo "Global FST (${POP1} vs ${POP2}):"
cat ${OUTDIR}/${POP1}.${POP2}.global_fst.txt

# windowed FST
echo "Estimating windowed FST..."
$ANGSD_CMD realSFS fst stats2 $FST_IDX_FILES \
    -win 50000 -step 25000 -type 2 \
    > ${OUTDIR}/${POP1}.${POP2}.windowed_fst.txt
[[ $? -ne 0 || ! -s ${OUTDIR}/${POP1}.${POP2}.windowed_fst.txt ]] && echo "Error: windowed fst stats failed" && exit 1

# summed 2D-SFS
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

rm -rf "$TMPDIR"
echo "Done"; date
