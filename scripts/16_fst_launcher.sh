#!/bin/bash
# 16_fst_launcher.sh - submit pairwise FST (all population pairs)

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

FST_OUT=${WORKING_DIR}/16_FST
PAIRS_FILE=${FST_OUT}/pop_pairs.txt

[[ ! -f "$PAIRS_FILE" ]] && echo "ERROR: pairs file not found — run 12_setup_angsd.sh first" && exit 1

NUM_PAIRS=$(wc -l < "$PAIRS_FILE")

echo "Submitting FST for ${NUM_PAIRS} population pairs"

bsub -J "fst[1-${NUM_PAIRS}]%30" \
     -n 4 -W 4:00 \
     -R "span[hosts=1] rusage[mem=8GB]" \
     -o "${PIPELINE_DIR}/logs/fst.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/fst.%J_%I.err" \
     bash "${PIPELINE_DIR}/16_fst.sh"
