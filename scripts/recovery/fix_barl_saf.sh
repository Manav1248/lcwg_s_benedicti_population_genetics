#!/bin/bash
#BSUB -J barl_ch1_saf
#BSUB -n 4
#BSUB -W 6:00
#BSUB -R "span[hosts=1] rusage[mem=8GB]"
#BSUB -o scripts/logs/barl_ch1_saf.%J.log
#BSUB -e scripts/logs/barl_ch1_saf.%J.err
# fix_barl_saf.sh - regenerate Bar_L Ch_1 SAF (the only 0-byte SAF)

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
BAM_LIST=${WORKING_DIR}/12_ANGSD_BEAGLE/pop_bamlists/Bar_L.bamlist
OUTDIR=${WORKING_DIR}/14_ANGSD_SAF/Bar_L/per_chrom

[[ ! -f "$BAM_LIST" ]] && echo "Error: BAM list not found: $BAM_LIST" && exit 1

# verify BAMs are real before running
echo "Verifying Bar_L BAMs..."
GOOD=0
BAD=0
while read BAM; do
    if [[ ! -s "$BAM" ]] || [[ $(stat -c%s "$BAM") -lt 1000 ]]; then
        echo "  BAD: $(basename $BAM) ($(stat -c%s "$BAM") bytes)"
        BAD=$((BAD + 1))
    else
        GOOD=$((GOOD + 1))
    fi
done < "$BAM_LIST"
echo "  ${GOOD} good, ${BAD} bad"

# allow Bar_L_F14 to be tiny (truncated R2 from facility) but not others
if [[ $BAD -gt 1 ]]; then
    echo "Error: too many bad BAMs — alignment may not have completed"
    exit 1
fi

echo "Running SAF: Bar_L, Ch_1"
echo "Samples: $(wc -l < "$BAM_LIST")"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} \
    $ANGSD_SIF \
    angsd -bam $BAM_LIST \
        -ref $REFERENCE \
        -anc $REFERENCE \
        -r Ch_1: \
        -doSaf 1 \
        -GL 2 \
        -doMajorMinor 1 \
        -minMapQ 20 \
        -minQ 20 \
        -uniqueOnly 1 \
        -remove_bads 1 \
        -only_proper_pairs 1 \
        -nThreads 4 \
        -out ${OUTDIR}/Bar_L.Ch_1

[[ $? -ne 0 ]] && echo "Error: SAF failed" && exit 1
[[ ! -s "${OUTDIR}/Bar_L.Ch_1.saf.idx" ]] && echo "Error: SAF index is empty" && exit 1

echo "SAF index: $(ls -lh ${OUTDIR}/Bar_L.Ch_1.saf.idx | awk '{print $5}')"
echo "SAF data:  $(ls -lh ${OUTDIR}/Bar_L.Ch_1.saf.gz | awk '{print $5}')"
echo "Done"; date
