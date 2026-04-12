#!/bin/bash
# 10b_genotype_by_interval_launcher.sh - submit GenotypeGVCFs array (11 chromosomes)

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

INT_DIR=${HC_DIR}/intervals
GROUPS_FILE=${INT_DIR}/interval_groups.txt
DB_DIR=${HC_DIR}/genomicsdb

[[ ! -f "$GROUPS_FILE" ]] && echo "ERROR: interval groups file not found" && exit 1

NUM_GROUPS=$(wc -l < "$GROUPS_FILE")

# verify all GenomicsDB workspaces exist
MISSING=0
while IFS= read -r GROUP; do
    if [[ ! -d "${DB_DIR}/${GROUP}" ]]; then
        echo "ERROR: missing workspace for ${GROUP}"
        MISSING=$((MISSING + 1))
    fi
done < "$GROUPS_FILE"
[[ $MISSING -gt 0 ]] && echo "ERROR: ${MISSING} workspaces missing — GenomicsDBImport not done?" && exit 1

echo "Submitting GenotypeGVCFs for ${NUM_GROUPS} chromosomes"

create_dir "${GENOTYPED_DIR}/by_interval"

bsub -J "genotype_interval[1-${NUM_GROUPS}]" \
     -n 2 -W 24:00 \
     -R "span[hosts=1] rusage[mem=16GB]" \
     -o "${PIPELINE_DIR}/logs/genotype_interval.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/genotype_interval.%J_%I.err" \
     bash "${PIPELINE_DIR}/10b_genotype_by_interval.sh"
