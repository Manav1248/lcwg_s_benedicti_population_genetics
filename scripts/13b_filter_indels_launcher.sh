#!/bin/bash
# 13b_filter_indels_launcher.sh - hard-filter indels from all-sites VCF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/13b_filter_indels.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/13b_filter_indels.config"

ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
[[ ! -f "$ALLSITES_VCF" ]] && echo "ERROR: all-sites VCF not found — run 11b_gather_launcher.sh first" && exit 1

create_dir $INDEL_LOGS_O $INDEL_LOGS_E

bsub -J "$JOB13B_NAME" \
     -n $JOB13B_CPUS -W $JOB13B_TIME \
     -R "span[hosts=1] rusage[mem=${JOB13B_MEMORY}]" \
     -o "${INDEL_LOGS_O}/filter_indels.%J.log" \
     -e "${INDEL_LOGS_E}/filter_indels.%J.err" \
     bash "${PIPELINE_DIR}/13b_filter_indels.sh"
