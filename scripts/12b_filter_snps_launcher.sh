#!/bin/bash
# 12b_filter_snps_launcher.sh - hard-filter SNPs from all-sites VCF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/12b_filter_snps.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/12b_filter_snps.config"

ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
[[ ! -f "$ALLSITES_VCF" ]] && echo "ERROR: all-sites VCF not found — run 11b_gather_launcher.sh first" && exit 1

create_dir $SNP_LOGS_O $SNP_LOGS_E

bsub -J "$JOB12B_NAME" \
     -n $JOB12B_CPUS -W $JOB12B_TIME \
     -R "span[hosts=1] rusage[mem=${JOB12B_MEMORY}]" \
     -o "${SNP_LOGS_O}/filter_snps.%J.log" \
     -e "${SNP_LOGS_E}/filter_snps.%J.err" \
     bash "${PIPELINE_DIR}/12b_filter_snps.sh"
