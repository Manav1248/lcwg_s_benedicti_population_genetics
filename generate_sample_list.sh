#!/bin/bash
# Scans a reads directory for paired FASTQ files and builds a sample list.
# Each line is Pop/SampleName (e.g., Bar_L/Bar_L_F01).
# Usage: bash generate_sample_list.sh /path/to/reads [output_file]

READS_DIR="${1:?Usage: $0 <reads_dir> [output_file]}"
OUTPUT="${2:-${READS_DIR}/sample_list.txt}"
[[ ! -d "$READS_DIR" ]] && echo "Error: $READS_DIR not found" && exit 1

> "$OUTPUT"
for r1 in "${READS_DIR}"/*/*_R1.fastq; do
    [[ ! -f "$r1" ]] && continue
    SAMPLE=$(basename "$r1" _R1.fastq)
    POP=$(basename "$(dirname "$r1")")
    echo "${POP}/${SAMPLE}" >> "$OUTPUT"
done

sort -o "$OUTPUT" "$OUTPUT"
echo "$(wc -l < "$OUTPUT") samples written to ${OUTPUT}"