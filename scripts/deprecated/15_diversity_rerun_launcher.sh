#!/bin/bash
source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

bsub -J "div_rerun[1-7]" \
     -n 4 -W 24:00 \
     -R "span[hosts=1] rusage[mem=16GB]" \
     -o "${PIPELINE_DIR}/logs/div_rerun.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/div_rerun.%J_%I.err" \
     bash "${PIPELINE_DIR}/15_diversity_rerun.sh"
