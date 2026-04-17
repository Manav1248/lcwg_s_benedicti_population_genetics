#!/bin/bash
# 10b_genotype_chunk_launcher.sh - submit GenotypeGVCFs for 10Mb chunks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/10b_chunks.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/10b_chunks.config"

INT_DIR=${HC_DIR}/intervals
CHUNK_FILE=${INT_DIR}/genotype_chunks.list
DB_DIR=${HC_DIR}/genomicsdb_chunks

[[ ! -f "$CHUNK_FILE" ]] && echo "ERROR: chunk list not found" && exit 1

NUM_CHUNKS=$(wc -l < "$CHUNK_FILE")

# verify all workspaces exist
MISSING=0
for i in $(seq 1 $NUM_CHUNKS); do
    PADDED=$(printf "%04d" $i)
    [[ ! -d "${DB_DIR}/chunk_${PADDED}" ]] && echo "ERROR: missing chunk_${PADDED}" && MISSING=$((MISSING + 1))
done
[[ $MISSING -gt 0 ]] && echo "ERROR: ${MISSING} workspaces missing" && exit 1

echo "Submitting GenotypeGVCFs for ${NUM_CHUNKS} chunks"

create_dir "${GENOTYPED_DIR}/by_chunk"

bsub -J "${JOB10B_GENO_NAME}[1-${NUM_CHUNKS}]" \
     -n $JOB10B_GENO_CPUS -W $JOB10B_GENO_TIME \
     -R "span[hosts=1] rusage[mem=${JOB10B_GENO_MEMORY}]" \
     -o "${PIPELINE_DIR}/logs/genotype_chunk.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/genotype_chunk.%J_%I.err" \
     bash "${PIPELINE_DIR}/10b_genotype_chunk.sh"
