#!/bin/bash
# 15_diversity.sh - merge per-chrom SAFs, estimate SFS, compute diversity stats
# array job: one job per population (11 total)

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
SAF_OUT=${WORKING_DIR}/14_ANGSD_SAF
DIV_OUT=${WORKING_DIR}/15_DIVERSITY

POP_LIST=${ANGSD_OUT}/pop_list.txt
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt

POP=$(sed -n "${LSB_JOBINDEX}p" "$POP_LIST")
[[ -z "$POP" ]] && echo "Error: no population for index ${LSB_JOBINDEX}" && exit 1

POP_SAF_DIR=${SAF_OUT}/${POP}/per_chrom
POP_DIV_DIR=${DIV_OUT}/${POP}
mkdir -p "$POP_DIV_DIR"

echo "Population: ${POP} (index ${LSB_JOBINDEX})"

module load apptainer

ANGSD_CMD="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $ANGSD_SIF"

# build list of per-chromosome SAF files for merging
SAF_FILES=""
while IFS= read -r CHR; do
    SAF_FILES="${SAF_FILES} ${POP_SAF_DIR}/${POP}.${CHR}.saf.idx"
done < "$CHROM_LIST"

# merge per-chromosome SAFs into genome-wide
echo "Merging per-chromosome SAFs..."
$ANGSD_CMD realSFS cat $SAF_FILES -outnames ${POP_DIV_DIR}/${POP}

[[ $? -ne 0 ]] && echo "Error: realSFS cat failed for ${POP}" && exit 1

# estimate 1D-SFS
echo "Estimating SFS..."
$ANGSD_CMD realSFS ${POP_DIV_DIR}/${POP}.saf.idx \
    -fold 1 \
    -P 4 \
    > ${POP_DIV_DIR}/${POP}.sfs

[[ $? -ne 0 ]] && echo "Error: realSFS failed for ${POP}" && exit 1

# estimate thetas per site
echo "Estimating thetas..."
$ANGSD_CMD realSFS saf2theta \
    ${POP_DIV_DIR}/${POP}.saf.idx \
    -sfs ${POP_DIV_DIR}/${POP}.sfs \
    -fold 1 \
    -outname ${POP_DIV_DIR}/${POP}

[[ $? -ne 0 ]] && echo "Error: saf2theta failed for ${POP}" && exit 1

# genome-wide summary
echo "Computing genome-wide diversity..."
$ANGSD_CMD thetaStat do_stat ${POP_DIV_DIR}/${POP}.thetas.idx

# windowed estimates (50kb windows, 25kb step)
echo "Computing windowed diversity..."
$ANGSD_CMD thetaStat do_stat ${POP_DIV_DIR}/${POP}.thetas.idx \
    -win 50000 -step 25000 \
    -outnames ${POP_DIV_DIR}/${POP}.thetasWindow

echo "Outputs:"
ls -lh ${POP_DIV_DIR}/${POP}.*
echo "Done"; date
