#!/bin/bash
# 11b_gather_launcher.sh - fix chunk VCFs and concatenate into all-sites VCF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/11b_gather.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/11b_gather.config"

CHUNK_DIR=${GENOTYPED_DIR}/by_chunk
[[ ! -d "$CHUNK_DIR" ]] && echo "ERROR: chunk VCFs not found — run 10b_genotype_chunk_launcher.sh first" && exit 1

NCHUNKS=$(ls ${CHUNK_DIR}/chunk_*.vcf.gz 2>/dev/null | wc -l)
[[ $NCHUNKS -eq 0 ]] && echo "ERROR: no chunk VCFs found in ${CHUNK_DIR}" && exit 1
echo "Found ${NCHUNKS} chunks to gather"

create_dir $GATHER_LOGS_O $GATHER_LOGS_E

bsub -J "$JOB11B_NAME" \
     -n $JOB11B_CPUS -W $JOB11B_TIME \
     -R "span[hosts=1] rusage[mem=${JOB11B_MEMORY}]" \
     -o "${GATHER_LOGS_O}/gather.%J.log" \
     -e "${GATHER_LOGS_E}/gather.%J.err" \
     bash "${PIPELINE_DIR}/11b_gather.sh"
