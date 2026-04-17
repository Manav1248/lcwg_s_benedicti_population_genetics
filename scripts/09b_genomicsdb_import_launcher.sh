#!/bin/bash
# 09b_genomicsdb_import_launcher.sh - submit GenomicsDBImport array (11 chromosomes)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/09b_genomicsdb_import.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/09b_genomicsdb_import.config"

INT_DIR=${HC_DIR}/intervals
GROUPS_FILE=${INT_DIR}/interval_groups.txt
SAMPLE_MAP=${INT_DIR}/sample_map.txt

[[ ! -f "$GROUPS_FILE" ]] && echo "ERROR: run 09b_setup_intervals.sh first" && exit 1
[[ ! -f "$SAMPLE_MAP" ]] && echo "ERROR: sample map not found" && exit 1

NUM_GROUPS=$(wc -l < "$GROUPS_FILE")

# spot-check first GVCF from sample map
FIRST_GVCF=$(head -1 "$SAMPLE_MAP" | cut -f2)
[[ ! -f "$FIRST_GVCF" ]] && echo "ERROR: GVCF not found: $FIRST_GVCF" && exit 1

echo "Submitting GenomicsDBImport for ${NUM_GROUPS} chromosomes"
echo "Sample map: $(wc -l < "$SAMPLE_MAP") samples"

bsub -J "${JOB09B_NAME}[1-${NUM_GROUPS}]" \
     -n $JOB09B_CPUS -W $JOB09B_TIME \
     -R "span[hosts=1] rusage[mem=${JOB09B_MEMORY}]" \
     -o "${PIPELINE_DIR}/logs/genomicsdb_import.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/genomicsdb_import.%J_%I.err" \
     bash "${PIPELINE_DIR}/09b_genomicsdb_import.sh"
