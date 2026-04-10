#!/bin/bash
#BSUB -J genotype_gvcfs
#BSUB -n 2
#BSUB -W 48:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o logs/genotype_gvcfs_%J.log
#BSUB -e logs/genotype_gvcfs_%J.err
# 10_genotype_gvcfs.sh - joint genotyping, retaining invariant sites

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

INPUT=${HC_DIR}/all_samples.g.vcf.gz
ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
TMPDIR=${GENOTYPED_DIR}/tmp_genotype
mkdir -p "$GENOTYPED_DIR" "$TMPDIR"

[[ ! -f "$INPUT" ]] && echo "Error: combined GVCF not found: $INPUT" && exit 1

module load apptainer

echo "Running GenotypeGVCFs (all sites)..."
apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "-Xmx14G -XX:ParallelGCThreads=1 -Djava.io.tmpdir=${TMPDIR}" \
        GenotypeGVCFs \
        -R $REFERENCE \
        -V $INPUT \
        -O $ALLSITES_VCF \
        --include-non-variant-sites

[[ $? -ne 0 ]] && echo "Error: GenotypeGVCFs failed" && rm -rf "$TMPDIR" && exit 1
[[ ! -f "$ALLSITES_VCF" ]] && echo "Error: output missing" && rm -rf "$TMPDIR" && exit 1

echo "All-sites VCF: $(du -h "$ALLSITES_VCF" | cut -f1)"

# count variant vs invariant sites
echo "Counting variant sites..."
apptainer exec \
    --bind ${GENOTYPED_DIR}:${GENOTYPED_DIR} \
    $GATK_SIF \
    bash -c "zgrep -vc '^#' ${ALLSITES_VCF}" > ${GENOTYPED_DIR}/total_sites.txt 2>/dev/null

echo "Total sites: $(cat ${GENOTYPED_DIR}/total_sites.txt)"
rm -rf "$TMPDIR"
echo "Done"; date
