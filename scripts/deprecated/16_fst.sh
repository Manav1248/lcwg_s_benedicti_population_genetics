#!/bin/bash
# 16_fst.sh - pairwise FST between two populations
# array job: one job per population pair

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
DIV_OUT=${WORKING_DIR}/15_DIVERSITY
FST_OUT=${WORKING_DIR}/16_FST
PAIRS_FILE=${FST_OUT}/pop_pairs.txt

[[ ! -f "$PAIRS_FILE" ]] && echo "Error: pairs file not found" && exit 1

PAIR_LINE=$(sed -n "${LSB_JOBINDEX}p" "$PAIRS_FILE")
POP1=$(echo "$PAIR_LINE" | cut -d' ' -f1)
POP2=$(echo "$PAIR_LINE" | cut -d' ' -f2)

[[ -z "$POP1" || -z "$POP2" ]] && echo "Error: no pair for index ${LSB_JOBINDEX}" && exit 1

SAF1=${DIV_OUT}/${POP1}/${POP1}.saf.idx
SAF2=${DIV_OUT}/${POP2}/${POP2}.saf.idx

[[ ! -f "$SAF1" ]] && echo "Error: SAF not found: $SAF1" && exit 1
[[ ! -f "$SAF2" ]] && echo "Error: SAF not found: $SAF2" && exit 1

OUTDIR=${FST_OUT}/pairwise
mkdir -p "$OUTDIR"

echo "FST: ${POP1} vs ${POP2} (job ${LSB_JOBINDEX})"

module load apptainer

ANGSD_CMD="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $ANGSD_SIF"

# estimate 2D-SFS
echo "Estimating 2D-SFS..."
$ANGSD_CMD realSFS $SAF1 $SAF2 \
    -fold 1 \
    -P 4 \
    > ${OUTDIR}/${POP1}.${POP2}.2dsfs

[[ $? -ne 0 ]] && echo "Error: 2D-SFS failed for ${POP1} vs ${POP2}" && exit 1

# global FST
echo "Estimating global FST..."
$ANGSD_CMD realSFS fst index $SAF1 $SAF2 \
    -sfs ${OUTDIR}/${POP1}.${POP2}.2dsfs \
    -fold 1 \
    -fstout ${OUTDIR}/${POP1}.${POP2}

$ANGSD_CMD realSFS fst stats ${OUTDIR}/${POP1}.${POP2}.fst.idx \
    > ${OUTDIR}/${POP1}.${POP2}.global_fst.txt

echo "Global FST (${POP1} vs ${POP2}):"
cat ${OUTDIR}/${POP1}.${POP2}.global_fst.txt

# windowed FST (50kb windows, 25kb step)
echo "Estimating windowed FST..."
$ANGSD_CMD realSFS fst stats2 ${OUTDIR}/${POP1}.${POP2}.fst.idx \
    -win 50000 -step 25000 -type 2 \
    > ${OUTDIR}/${POP1}.${POP2}.windowed_fst.txt

echo "Done"; date
