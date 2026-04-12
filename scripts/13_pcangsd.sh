#!/bin/bash
#BSUB -J pcangsd
#BSUB -n 8
#BSUB -W 2:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o logs/pcangsd_%J.log
#BSUB -e logs/pcangsd_%J.err
# 13_pcangsd.sh - PCA and admixture from Beagle genotype likelihoods

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

PCANGSD_SIF=${CONT}/pcangsd_1.36.4--py310hbcdfcc8_1.sif
BEAGLE=${WORKING_DIR}/12_ANGSD_BEAGLE/all_chrom.beagle.gz
OUTDIR=${WORKING_DIR}/13_PCANGSD

[[ ! -f "$BEAGLE" ]] && echo "Error: merged Beagle file not found" && exit 1

module load apptainer

# PCA (covariance matrix)
echo "Running PCAngsd..."
apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR} \
    $PCANGSD_SIF \
    pcangsd -b $BEAGLE \
        -o ${OUTDIR}/pcangsd \
        -t 8 \
        --admix \
        --admix-auto 10000 \
        --sites-save \
        --maf-save

[[ $? -ne 0 ]] && echo "Error: PCAngsd failed" && exit 1

echo "Outputs in ${OUTDIR}/"
ls -lh ${OUTDIR}/pcangsd.*
echo "Done"; date
