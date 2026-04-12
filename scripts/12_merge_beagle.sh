#!/bin/bash
#BSUB -J merge_beagle
#BSUB -n 1
#BSUB -W 2:00
#BSUB -R "span[hosts=1] rusage[mem=8GB]"
#BSUB -o logs/merge_beagle_%J.log
#BSUB -e logs/merge_beagle_%J.err
# 12_merge_beagle.sh - concatenate per-chromosome Beagle GL files

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt
PER_CHROM=${ANGSD_OUT}/per_chrom
MERGED=${ANGSD_OUT}/all_chrom.beagle.gz

# header from first chromosome
FIRST_CHR=$(head -1 "$CHROM_LIST")
zcat ${PER_CHROM}/${FIRST_CHR}.beagle.gz | head -1 | gzip > "$MERGED"

# append data (skip header) from each chromosome
while IFS= read -r CHR; do
    FILE="${PER_CHROM}/${CHR}.beagle.gz"
    [[ ! -f "$FILE" ]] && echo "Error: missing ${FILE}" && exit 1
    zcat "$FILE" | tail -n+2 | gzip >> "$MERGED"
done < "$CHROM_LIST"

NSITES=$(zcat "$MERGED" | tail -n+2 | wc -l)
echo "Merged Beagle: ${NSITES} sites"
echo "Output: ${MERGED}"
echo "Done"; date
