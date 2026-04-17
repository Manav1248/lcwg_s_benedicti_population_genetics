#!/bin/bash
# re-run diversity for the 7 pops that walltime'd out
# adds -tole and -maxIter to realSFS, bumps walltime

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
SAF_OUT=${WORKING_DIR}/14_ANGSD_SAF
DIV_OUT=${WORKING_DIR}/15_DIVERSITY
CHROM_LIST=${WORKING_DIR}/12_ANGSD_BEAGLE/chrom_list.txt

# hardcoded list of failed pops
POPS=(Bar_L Beau FL Gal LBA Moss UNCW)
POP=${POPS[$LSB_JOBINDEX-1]}
[[ -z "$POP" ]] && echo "Error: no pop for index ${LSB_JOBINDEX}" && exit 1

POP_SAF_DIR=${SAF_OUT}/${POP}/per_chrom
POP_DIV_DIR=${DIV_OUT}/${POP}
mkdir -p "$POP_DIV_DIR"

echo "Population: ${POP}"

module load apptainer
ANGSD_CMD="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $ANGSD_SIF"

# build list of per-chrom SAFs
SAF_FILES=""
while IFS= read -r CHR; do
    SAF_FILES="${SAF_FILES} ${POP_SAF_DIR}/${POP}.${CHR}.saf.idx"
done < "$CHROM_LIST"

# merge per-chrom SAFs (skip if already done)
if [[ ! -f "${POP_DIV_DIR}/${POP}.saf.idx" ]]; then
    echo "Merging SAFs..."
    $ANGSD_CMD realSFS cat $SAF_FILES -outnames ${POP_DIV_DIR}/${POP}
    [[ $? -ne 0 ]] && echo "Error: realSFS cat failed" && exit 1
fi

# estimate 1D-SFS with tighter convergence and iteration cap
echo "Estimating SFS (with tolerance/maxIter)..."
$ANGSD_CMD realSFS ${POP_DIV_DIR}/${POP}.saf.idx \
    -fold 1 \
    -P 4 \
    -tole 1e-6 \
    -maxIter 100 \
    > ${POP_DIV_DIR}/${POP}.sfs
[[ $? -ne 0 ]] && echo "Error: realSFS failed" && exit 1

# thetas per site
echo "Estimating thetas..."
$ANGSD_CMD realSFS saf2theta \
    ${POP_DIV_DIR}/${POP}.saf.idx \
    -sfs ${POP_DIV_DIR}/${POP}.sfs \
    -fold 1 \
    -outname ${POP_DIV_DIR}/${POP}
[[ $? -ne 0 ]] && echo "Error: saf2theta failed" && exit 1

# genome-wide
echo "Computing genome-wide stats..."
$ANGSD_CMD thetaStat do_stat ${POP_DIV_DIR}/${POP}.thetas.idx

# windowed
echo "Computing windowed stats..."
$ANGSD_CMD thetaStat do_stat ${POP_DIV_DIR}/${POP}.thetas.idx \
    -win 50000 -step 25000 \
    -outnames ${POP_DIV_DIR}/${POP}.thetasWindow

ls -lh ${POP_DIV_DIR}/${POP}.*
echo "Done"; date
