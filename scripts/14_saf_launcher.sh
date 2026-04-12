#!/bin/bash
# 14_saf_launcher.sh - submit per-population per-chromosome SAF array

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
POP_LIST=${ANGSD_OUT}/pop_list.txt
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt

[[ ! -f "$POP_LIST" ]] && echo "ERROR: run 12_setup_angsd.sh first" && exit 1
[[ ! -f "$CHROM_LIST" ]] && echo "ERROR: chromosome list not found" && exit 1

NUM_POPS=$(wc -l < "$POP_LIST")
NUM_CHROM=$(wc -l < "$CHROM_LIST")
TOTAL=$((NUM_POPS * NUM_CHROM))

echo "Submitting SAF estimation: ${NUM_POPS} populations x ${NUM_CHROM} chromosomes = ${TOTAL} jobs"

bsub -J "saf[1-${TOTAL}]%60" \
     -n 4 -W 6:00 \
     -R "span[hosts=1] rusage[mem=8GB]" \
     -o "${PIPELINE_DIR}/logs/saf.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/saf.%J_%I.err" \
     bash "${PIPELINE_DIR}/14_saf.sh"
