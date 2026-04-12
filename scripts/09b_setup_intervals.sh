#!/bin/bash
# 09b_setup_intervals.sh - create per-chromosome interval lists and sample map
# run once on login node before submitting array jobs
# note: unplaced scaffolds are excluded; to include them, add a scaffolds.list
# entry to interval_groups.txt and generate the list from the .fai

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

INT_DIR=${HC_DIR}/intervals
mkdir -p "$INT_DIR"

FAI=${REFERENCE}.fai
[[ ! -f "$FAI" ]] && echo "Error: reference index not found: $FAI" && exit 1

# one .list file per chromosome
for CHR in Ch_1 Ch_2 Ch_3 Ch_4 Ch_5 Ch_6 Ch_7 Ch_8 Ch_9 Ch_10 Ch_11; do
    echo "$CHR" > "${INT_DIR}/${CHR}.list"
done

# master list for array indexing (line number = LSB_JOBINDEX)
cat > "${INT_DIR}/interval_groups.txt" <<EOF
Ch_1
Ch_2
Ch_3
Ch_4
Ch_5
Ch_6
Ch_7
Ch_8
Ch_9
Ch_10
Ch_11
EOF

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
