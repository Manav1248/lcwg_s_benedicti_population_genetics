#!/bin/bash
# 12_beagle_gl.sh - estimate genotype likelihoods in Beagle format for one chromosome
# array job: one job per chromosome (11 total)

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ANGSD_OUT=${WORKING_DIR}/12_ANGSD_BEAGLE
ANGSD_SIF=${CONT}/angsd_0.940--h13024bc_4.sif
BAM_LIST=${ANGSD_OUT}/all_samples.bamlist
CHROM_LIST=${ANGSD_OUT}/chrom_list.txt

CHR=$(sed -n "${LSB_JOBINDEX}p" "$CHROM_LIST")
[[ -z "$CHR" ]] && echo "Error: no chromosome for index ${LSB_JOBINDEX}" && exit 1
[[ ! -f "$BAM_LIST" ]] && echo "Error: BAM list not found" && exit 1

OUTDIR=${ANGSD_OUT}/per_chrom
mkdir -p "$OUTDIR"

echo "Chromosome: ${CHR} (index ${LSB_JOBINDEX})"
echo "Samples: $(wc -l < "$BAM_LIST")"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} \
    $ANGSD_SIF \
    angsd -bam $BAM_LIST \
        -ref $REFERENCE \
        -r ${CHR}: \
        -GL 2 \
        -doGlf 2 \
        -doMaf 1 \
        -doMajorMinor 1 \
        -SNP_pval 1e-6 \
        -minMapQ 20 \
        -minQ 20 \
        -minMaf 0.05 \
        -uniqueOnly 1 \
        -remove_bads 1 \
        -only_proper_pairs 1 \
        -nThreads 8 \
        -out ${OUTDIR}/${CHR}

[[ $? -ne 0 ]] && echo "Error: ANGSD failed for ${CHR}" && exit 1

echo "Sites for ${CHR}: $(zcat ${OUTDIR}/${CHR}.mafs.gz | tail -n+2 | wc -l)"
echo "Done"; date
