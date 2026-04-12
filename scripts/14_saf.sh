#!/bin/bash
# 14_saf.sh - estimate SAF for one population on one chromosome
# array job: indexed by (pop_index - 1) * 11 + chrom_index
# total jobs = num_pops * 11

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
SAF_OUT=${WORKING_DIR}/14_ANGSD_SAF

POP_LIST=${ANGSD_OUT}/pop_list.txt
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt
NUM_CHROM=$(wc -l < "$CHROM_LIST")

# decode array index into population + chromosome
POP_IDX=$(( (LSB_JOBINDEX - 1) / NUM_CHROM + 1 ))
CHR_IDX=$(( (LSB_JOBINDEX - 1) % NUM_CHROM + 1 ))

POP=$(sed -n "${POP_IDX}p" "$POP_LIST")
CHR=$(sed -n "${CHR_IDX}p" "$CHROM_LIST")

[[ -z "$POP" ]] && echo "Error: no population for index ${POP_IDX}" && exit 1
[[ -z "$CHR" ]] && echo "Error: no chromosome for index ${CHR_IDX}" && exit 1

BAM_LIST=${ANGSD_OUT}/pop_bamlists/${POP}.bamlist
[[ ! -f "$BAM_LIST" ]] && echo "Error: BAM list not found: $BAM_LIST" && exit 1

OUTDIR=${SAF_OUT}/${POP}/per_chrom
mkdir -p "$OUTDIR"

echo "Population: ${POP}, Chromosome: ${CHR} (job ${LSB_JOBINDEX})"
echo "Samples: $(wc -l < "$BAM_LIST")"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} \
    $ANGSD_SIF \
    angsd -bam $BAM_LIST \
        -ref $REFERENCE \
        -anc $REFERENCE \
        -r ${CHR}: \
        -doSaf 1 \
        -GL 2 \
        -doMajorMinor 1 \
        -minMapQ 20 \
        -minQ 20 \
        -uniqueOnly 1 \
        -remove_bads 1 \
        -only_proper_pairs 1 \
        -nThreads 4 \
        -out ${OUTDIR}/${POP}.${CHR}

[[ $? -ne 0 ]] && echo "Error: SAF failed for ${POP} ${CHR}" && exit 1

echo "Done"; date
