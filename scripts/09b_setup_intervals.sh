#!/bin/bash
# 09b_setup_intervals.sh - create per-chromosome interval lists and sample map
# run once on login node before submitting array jobs
# note: unplaced scaffolds are excluded; to include them, add a scaffolds.list
# entry to interval_groups.txt and generate the list from the .fai

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/global_config.sh" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/global_config.sh"

INT_DIR=${HC_DIR}/intervals
mkdir -p "$INT_DIR"

FAI=${REFERENCE}.fai
CHR_LIST=${SCRIPT_DIR}/chromosome_list.txt
[[ ! -f "$FAI" ]] && echo "Error: reference index not found: $FAI" && exit 1
[[ ! -f "$CHR_LIST" ]] && echo "Error: chromosome_list.txt not found: $CHR_LIST" && exit 1

# one .list file per chromosome
while IFS= read -r CHR; do
    echo "$CHR" > "${INT_DIR}/${CHR}.list"
done < "$CHR_LIST"

# master list for array indexing (line number = LSB_JOBINDEX)
cp "$CHR_LIST" "${INT_DIR}/interval_groups.txt"

# sample map for GenomicsDBImport (sample_name <tab> gvcf_path)
SAMPLE_MAP=${INT_DIR}/sample_map.txt
> "$SAMPLE_MAP"
while IFS= read -r entry; do
    NAME=$(basename "$entry")
    SUBDIR=$(dirname "$entry")
    GVCF=${GVCF_DIR}/${SUBDIR}/${NAME}.g.vcf.gz
    echo -e "${NAME}\t${GVCF}" >> "$SAMPLE_MAP"
done < "$XFILE"

echo "Created 11 chromosome interval lists"
echo "Sample map: $(wc -l < "$SAMPLE_MAP") samples"
echo "Done"
