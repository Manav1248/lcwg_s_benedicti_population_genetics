#!/bin/bash
source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

FST_OUT=${WORKING_DIR}/16_FST
PAIRS_FILE=${FST_OUT}/pop_pairs.txt
NUM_PAIRS=$(wc -l < "$PAIRS_FILE")

echo "Submitting fast FST rerun for ${NUM_PAIRS} pairs (skips completed, resumes from tmp)"

bsub -J "fst_rerun[1-${NUM_PAIRS}]%30" \
     -n 8 -W 48:00 \
     -R "span[hosts=1] rusage[mem=24GB]" \
     -o "${PIPELINE_DIR}/logs/fst_rerun.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/fst_rerun.%J_%I.err" \
     bash "${PIPELINE_DIR}/16_fst_fast_rerun.sh"
