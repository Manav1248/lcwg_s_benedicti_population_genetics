#!/bin/bash
#BSUB -J filter_variants
#BSUB -n 2
#BSUB -W 12:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o logs/filter_variants_%J.log
#BSUB -e logs/filter_variants_%J.err
# 11_select_filter_variants.sh - split SNPs/indels + hard filter
# adapted from GATK best practices for non-model organisms (no VQSR)

pwd; hostname; date

source /share/ivirus/dhermos/zakas_project/scripts/global_config.sh

ALLSITES_VCF=${GENOTYPED_DIR}/all_samples.allsites.vcf.gz
OUTDIR=${GENOTYPED_DIR}/filtered
mkdir -p "$OUTDIR"

[[ ! -f "$ALLSITES_VCF" ]] && echo "Error: all-sites VCF not found" && exit 1

module load apptainer

GATK_CMD="apptainer exec --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR} $GATK_SIF gatk"
JAVA_OPTS="--java-options -Xmx14G"

# select SNPs
echo "Selecting SNPs..."
$GATK_CMD $JAVA_OPTS SelectVariants \
    -R $REFERENCE \
    -V $ALLSITES_VCF \
    --select-type-to-include SNP \
    -O ${OUTDIR}/snps.raw.vcf.gz

# select indels
echo "Selecting indels..."
$GATK_CMD $JAVA_OPTS SelectVariants \
    -R $REFERENCE \
    -V $ALLSITES_VCF \
    --select-type-to-include INDEL \
    -O ${OUTDIR}/indels.raw.vcf.gz

# extract quality scores for diagnostic plots (before filtering)
echo "Extracting SNP quality scores..."
$GATK_CMD $JAVA_OPTS VariantsToTable \
    -R $REFERENCE \
    -V ${OUTDIR}/snps.raw.vcf.gz \
    -F CHROM -F POS -F QUAL -F QD -F DP -F MQ -F MQRankSum -F FS -F ReadPosRankSum -F SOR \
    --show-filtered \
    -O ${OUTDIR}/snps.raw.table

echo "Extracting indel quality scores..."
$GATK_CMD $JAVA_OPTS VariantsToTable \
    -R $REFERENCE \
    -V ${OUTDIR}/indels.raw.vcf.gz \
    -F CHROM -F POS -F QUAL -F QD -F DP -F MQ -F MQRankSum -F FS -F ReadPosRankSum -F SOR \
    --show-filtered \
    -O ${OUTDIR}/indels.raw.table

# hard filter SNPs
echo "Filtering SNPs..."
$GATK_CMD $JAVA_OPTS VariantFiltration \
    -R $REFERENCE \
    -V ${OUTDIR}/snps.raw.vcf.gz \
    -filter "QD < 2.0" --filter-name "QD2" \
    -filter "FS > 60.0" --filter-name "FS60" \
    -filter "MQ < 40.0" --filter-name "MQ40" \
    -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
    -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
    -filter "SOR > 3.0" --filter-name "SOR3" \
    -O ${OUTDIR}/snps.filtered.vcf.gz

# hard filter indels
echo "Filtering indels..."
$GATK_CMD $JAVA_OPTS VariantFiltration \
    -R $REFERENCE \
    -V ${OUTDIR}/indels.raw.vcf.gz \
    -filter "QD < 2.0" --filter-name "QD2" \
    -filter "FS > 200.0" --filter-name "FS200" \
    -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \
    -filter "SOR > 10.0" --filter-name "SOR10" \
    -O ${OUTDIR}/indels.filtered.vcf.gz

# extract PASS-only
echo "Extracting PASS variants..."
$GATK_CMD $JAVA_OPTS SelectVariants \
    -R $REFERENCE \
    -V ${OUTDIR}/snps.filtered.vcf.gz \
    --exclude-filtered \
    -O ${OUTDIR}/snps.pass.vcf.gz

$GATK_CMD $JAVA_OPTS SelectVariants \
    -R $REFERENCE \
    -V ${OUTDIR}/indels.filtered.vcf.gz \
    --exclude-filtered \
    -O ${OUTDIR}/indels.pass.vcf.gz

# counts
for f in snps.raw snps.pass indels.raw indels.pass; do
    N=$(apptainer exec --bind ${OUTDIR}:${OUTDIR} $GATK_SIF bash -c "zgrep -vc '^#' ${OUTDIR}/${f}.vcf.gz" 2>/dev/null)
    echo "${f}: ${N}"
done
