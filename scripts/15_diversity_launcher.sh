#!/bin/bash
# 15_diversity_launcher.sh - submit diversity estimation (11 populations)

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
POP_LIST=${ANGSD_OUT}/pop_list.txt

[[ ! -f "$POP_LIST" ]] && echo "ERROR: population list not found" && exit 1

NUM_POPS=$(wc -l < "$POP_LIST")

echo "Submitting diversity estimation for ${NUM_POPS} populations"

bsub -J "diversity[1-${NUM_POPS}]" \
     -n 4 -W 6:00 \
     -R "span[hosts=1] rusage[mem=8GB]" \
     -o "${PIPELINE_DIR}/logs/diversity.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/diversity.%J_%I.err" \
     bash "${PIPELINE_DIR}/15_diversity.sh"
