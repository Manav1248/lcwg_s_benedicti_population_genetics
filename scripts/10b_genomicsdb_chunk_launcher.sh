#!/bin/bash
# 10b_genomicsdb_chunk_launcher.sh - submit GenomicsDBImport for 10Mb chunks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/10b_chunks.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/10b_chunks.config"

INT_DIR=${HC_DIR}/intervals
CHUNK_FILE=${INT_DIR}/genotype_chunks.list
SAMPLE_MAP=${INT_DIR}/sample_map.txt

[[ ! -f "$CHUNK_FILE" ]] && echo "ERROR: run 10b_setup_chunks.sh first" && exit 1
[[ ! -f "$SAMPLE_MAP" ]] && echo "ERROR: sample map not found" && exit 1

NUM_CHUNKS=$(wc -l < "$CHUNK_FILE")

FIRST_GVCF=$(head -1 "$SAMPLE_MAP" | cut -f2)
[[ ! -f "$FIRST_GVCF" ]] && echo "ERROR: GVCF not found: $FIRST_GVCF" && exit 1

echo "Submitting GenomicsDBImport for ${NUM_CHUNKS} chunks"

create_dir $CHUNKS_LOGS_O $CHUNKS_LOGS_E

bsub -J "${JOB10B_IMPORT_NAME}[1-${NUM_CHUNKS}]" \
     -n $JOB10B_IMPORT_CPUS -W $JOB10B_IMPORT_TIME \
     -R "span[hosts=1] rusage[mem=${JOB10B_IMPORT_MEMORY}]" \
     -o "${CHUNKS_LOGS_O}/genomicsdb_chunk.%J_%I.log" \
     -e "${CHUNKS_LOGS_E}/genomicsdb_chunk.%J_%I.err" \
     bash "${PIPELINE_DIR}/10b_genomicsdb_chunk.sh"
