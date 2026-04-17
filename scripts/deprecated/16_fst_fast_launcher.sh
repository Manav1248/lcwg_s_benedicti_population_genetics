#!/bin/bash
# 16_fst_fast_launcher.sh - submit fast per-chromosome FST (55 pairs)

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

FST_OUT=${WORKING_DIR}/16_FST
PAIRS_FILE=${FST_OUT}/pop_pairs.txt

[[ ! -f "$PAIRS_FILE" ]] && echo "ERROR: pairs file not found" && exit 1

NUM_PAIRS=$(wc -l < "$PAIRS_FILE")

echo "Submitting fast FST for ${NUM_PAIRS} population pairs"

bsub -J "fst_fast[1-${NUM_PAIRS}]%30" \
     -n 8 -W 12:00 \
     -R "span[hosts=1] rusage[mem=16GB]" \
     -o "${PIPELINE_DIR}/logs/fst_fast.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/fst_fast.%J_%I.err" \
     bash "${PIPELINE_DIR}/16_fst_fast.sh"
