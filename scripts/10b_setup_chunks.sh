#!/bin/bash
# 10b_setup_chunks.sh - generate 10Mb interval chunks for parallelized genotyping
# run once on login node before submitting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/10b_chunks.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/10b_chunks.config"

FAI=${REFERENCE}.fai
INT_DIR=${HC_DIR}/intervals
CHUNK_FILE=${INT_DIR}/genotype_chunks.list

[[ ! -f "$FAI" ]] && echo "Error: .fai not found" && exit 1

> "$CHUNK_FILE"

# generate chunks in dictionary order (Ch_1 Ch_10 Ch_11 Ch_2 ... Ch_9)
for CHR in Ch_1 Ch_10 Ch_11 Ch_2 Ch_3 Ch_4 Ch_5 Ch_6 Ch_7 Ch_8 Ch_9; do
    LEN=$(awk -v c="$CHR" '$1==c {print $2}' "$FAI")
    [[ -z "$LEN" ]] && echo "Error: $CHR not found in .fai" && exit 1
    START=1
    while [[ $START -le $LEN ]]; do
        END=$((START + CHUNK_SIZE - 1))
        [[ $END -gt $LEN ]] && END=$LEN
        echo "${CHR}:${START}-${END}" >> "$CHUNK_FILE"
        START=$((END + 1))
    done
done

NUM_CHUNKS=$(wc -l < "$CHUNK_FILE")
echo "Generated ${NUM_CHUNKS} chunks (${CHUNK_SIZE}bp each)"
head -3 "$CHUNK_FILE"
echo "..."
tail -3 "$CHUNK_FILE"
