#!/bin/bash
# 12_beagle_gl_launcher.sh - submit per-chromosome Beagle GL array (11 chromosomes)

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt
BAM_LIST=${ANGSD_OUT}/all_samples.bamlist

[[ ! -f "$CHROM_LIST" ]] && echo "ERROR: run 12_setup_angsd.sh first" && exit 1
[[ ! -f "$BAM_LIST" ]] && echo "ERROR: BAM list not found" && exit 1

NUM_CHROM=$(wc -l < "$CHROM_LIST")

# spot-check first BAM
FIRST_BAM=$(head -1 "$BAM_LIST")
[[ ! -f "$FIRST_BAM" ]] && echo "ERROR: BAM not found: $FIRST_BAM" && exit 1

echo "Submitting Beagle GL for ${NUM_CHROM} chromosomes"
echo "Samples: $(wc -l < "$BAM_LIST")"

create_dir "${ANGSD_OUT}/per_chrom"

bsub -J "beagle_gl[1-${NUM_CHROM}]" \
     -n 8 -W 12:00 \
     -R "span[hosts=1] rusage[mem=16GB]" \
     -o "${PIPELINE_DIR}/logs/beagle_gl.%J_%I.log" \
     -e "${PIPELINE_DIR}/logs/beagle_gl.%J_%I.err" \
     bash "${PIPELINE_DIR}/12_beagle_gl.sh"
