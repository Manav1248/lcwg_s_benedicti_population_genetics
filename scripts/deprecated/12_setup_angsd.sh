#!/bin/bash
# 12_setup_angsd.sh - create BAM lists, population lists, and directory structure
# run once on login node before submitting ANGSD jobs

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
PCANGSD_OUT=${WORKING_DIR}/13_PCANGSD
SAF_OUT=${WORKING_DIR}/14_ANGSD_SAF
DIV_OUT=${WORKING_DIR}/15_DIVERSITY
FST_OUT=${WORKING_DIR}/16_FST

mkdir -p $ANGSD_OUT $PCANGSD_OUT $SAF_OUT $DIV_OUT $FST_OUT

# chromosome list for array indexing
cat > ${ANGSD_OUT}/chrom_list.txt <<EOF
Ch_1
Ch_2
Ch_3
Ch_4
Ch_5
Ch_6
Ch_7
Ch_8
Ch_9
Ch_10
Ch_11
EOF

# master BAM list (all samples, ANGSD BAMs with dups flagged)
BAM_LIST=${ANGSD_OUT}/all_samples.bamlist
> "$BAM_LIST"
while IFS= read -r entry; do
    NAME=$(basename "$entry")
    SUBDIR=$(dirname "$entry")
    BAM=${ANGSD_BAM_DIR}/${SUBDIR}/${NAME}.sorted.markdup.bam
    if [[ ! -f "$BAM" ]]; then
        echo "Warning: BAM not found: $BAM"
    fi
    echo "$BAM" >> "$BAM_LIST"
done < "$XFILE"
echo "Master BAM list: $(wc -l < "$BAM_LIST") samples"

# per-population BAM lists
POP_DIR=${ANGSD_OUT}/pop_bamlists
mkdir -p "$POP_DIR"
while IFS= read -r entry; do
    NAME=$(basename "$entry")
    SUBDIR=$(dirname "$entry")
    BAM=${ANGSD_BAM_DIR}/${SUBDIR}/${NAME}.sorted.markdup.bam
    echo "$BAM" >> "${POP_DIR}/${SUBDIR}.bamlist"
done < "$XFILE"

echo "Per-population BAM lists:"
for f in ${POP_DIR}/*.bamlist; do
    POP=$(basename "$f" .bamlist)
    echo "  ${POP}: $(wc -l < "$f") samples"
done

# population list for array indexing
ls ${POP_DIR}/*.bamlist | xargs -I{} basename {} .bamlist | sort > ${ANGSD_OUT}/pop_list.txt
echo "Population list: $(wc -l < "${ANGSD_OUT}/pop_list.txt") populations"

# generate all pairwise population combinations for FST
POP_LIST=${ANGSD_OUT}/pop_list.txt
PAIRS=${FST_OUT}/pop_pairs.txt
> "$PAIRS"
POPS=($(cat "$POP_LIST"))
for ((i=0; i<${#POPS[@]}; i++)); do
    for ((j=i+1; j<${#POPS[@]}; j++)); do
        echo "${POPS[$i]} ${POPS[$j]}" >> "$PAIRS"
    done
done
echo "FST pairs: $(wc -l < "$PAIRS")"

echo "Done"
