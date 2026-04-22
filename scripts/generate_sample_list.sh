#!/bin/bash
# generate_sample_list.sh - Build master XFILE from population subdirectories
#
# Scans all Pop_DevType directories (Bar_L, Bar_P, etc.) for paired reads
# and writes one line per sample: SUBDIR/SAMPLE_PREFIX
#
# Usage:
#   ./generate_sample_list.sh /path/to/renamed_reads
#   ./generate_sample_list.sh /path/to/renamed_reads /path/to/output.txt
#
# Output format (one line per sample):
#   Bar_L/Bar_L_01
#   Bar_L/Bar_L_02
#   Bar_P/Bar_P_01
#   ...

READS_DIR="${1:?Usage: $0 <renamed_reads_dir> [output_file]}"
OUTPUT="${2:-${READS_DIR}/sample_list.txt}"

if [[ ! -d "$READS_DIR" ]]; then
    echo "Error: Directory not found: $READS_DIR"
    exit 1
fi

> "$OUTPUT"
FOUND=0
MISSING_PAIR=0
DIRS_SCANNED=0

# Scan each population subdirectory
for pop_dir in "${READS_DIR}"/*/; do
    [[ ! -d "$pop_dir" ]] && continue
    POP=$(basename "$pop_dir")

    # Skip non-population dirs (logs, unused_reads, etc.)
    [[ "$POP" == "logs" || "$POP" == "unused_reads" ]] && continue

    DIRS_SCANNED=$((DIRS_SCANNED + 1))
    DIR_COUNT=0

    # Find all R1 files in this directory
    for r1 in "${pop_dir}"*_R1.fastq; do
        [[ ! -f "$r1" ]] && continue
        SAMPLE=$(basename "$r1" _R1.fastq)
        r2="${pop_dir}${SAMPLE}_R2.fastq"

        if [[ -f "$r2" ]]; then
            # Write as SUBDIR/SAMPLE_PREFIX
            echo "${POP}/${SAMPLE}" >> "$OUTPUT"
            FOUND=$((FOUND + 1))
            DIR_COUNT=$((DIR_COUNT + 1))
        else
            echo "  Warning: No R2 for ${SAMPLE} in ${POP}/"
            MISSING_PAIR=$((MISSING_PAIR + 1))
        fi
    done
    echo "  ${POP}: ${DIR_COUNT} samples"
done

if [[ $FOUND -eq 0 ]]; then
    echo "Error: No paired reads (*_R1.fastq + *_R2.fastq) found"
    rm -f "$OUTPUT"
    exit 1
fi

# Sort for reproducibility
sort -o "$OUTPUT" "$OUTPUT"

echo ""
echo "=== Summary ==="
echo "  Directories scanned: ${DIRS_SCANNED}"
echo "  Total samples:       ${FOUND}"
[[ $MISSING_PAIR -gt 0 ]] && echo "  Missing pairs:       ${MISSING_PAIR}"
echo "  Output: ${OUTPUT}"
echo ""
echo "To use with the pipeline, set in global_config.sh:"
echo "  export XFILE=${OUTPUT}"
echo "  export READS_BASE=${READS_DIR}"
