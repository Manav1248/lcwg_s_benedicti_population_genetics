#!/bin/bash
# 10b_genotype_by_interval.sh - joint genotyping from GenomicsDB for one chromosome
# array job: one job per chromosome (11 total)

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

INT_DIR=${HC_DIR}/intervals
DB_DIR=${HC_DIR}/genomicsdb
OUTDIR=${GENOTYPED_DIR}/by_interval
TMPDIR=${OUTDIR}/tmp_${LSB_JOBINDEX}

# which chromosome?
GROUP=$(sed -n "${LSB_JOBINDEX}p" "${INT_DIR}/interval_groups.txt")
[[ -z "$GROUP" ]] && echo "Error: no interval group for index ${LSB_JOBINDEX}" && exit 1

WORKSPACE="${DB_DIR}/${GROUP}"
OUTPUT="${OUTDIR}/${GROUP}.allsites.vcf.gz"

[[ ! -d "$WORKSPACE" ]] && echo "Error: GenomicsDB workspace not found: $WORKSPACE" && exit 1

mkdir -p "$OUTDIR" "$TMPDIR"

echo "Interval group: ${GROUP} (index ${LSB_JOBINDEX})"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "-Xmx14G -XX:ParallelGCThreads=1 -Djava.io.tmpdir=${TMPDIR}" \
        GenotypeGVCFs \
        -R $REFERENCE \
        -V gendb://${WORKSPACE} \
        -O $OUTPUT \
        --include-non-variant-sites

[[ $? -ne 0 ]] && echo "Error: GenotypeGVCFs failed for ${GROUP}" && rm -rf "$TMPDIR" && exit 1
[[ ! -f "$OUTPUT" ]] && echo "Error: output missing for ${GROUP}" && rm -rf "$TMPDIR" && exit 1

echo "Genotyped VCF for ${GROUP}: $(du -h "$OUTPUT" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done"; date
