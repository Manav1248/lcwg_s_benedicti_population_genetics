#!/bin/bash
# global_config.sh - Shared variables for Streblospio QC pipeline
#
# Key difference from metagenomics pipeline:
#   Reads live in population subdirectories (Bar_L/, Bar_P/, etc.)
#   XFILE entries are: SUBDIR/SAMPLE_PREFIX (e.g., Bar_L/Bar_L_01)

# ---- EDIT THESE PATHS ----
export WORKING_DIR=/share/ivirus/dhermos/zakas_project
export READS_BASE=/share/ivirus/dhermos/zakas_project/reads
export XFILE=/share/ivirus/dhermos/zakas_project/scripts/full_sample_list.txt
export PIPELINE_DIR=/share/ivirus/dhermos/zakas_project/scripts
# ---------------------------

# Containers
export CONT=/rs1/shares/brc/admin/containers/images
export APPT=/usr/local/apps/apptainer/1.4.2-1/bin/apptainer
export FASTQC_SIF=$CONT/quay.io_biocontainers_fastqc:0.12.1--hdfd78af_0.sif
export TRIMMOMATIC_SIF=$CONT/quay.io_biocontainers_trimmomatic:0.40--hdfd78af_0.sif
export MULTIQC_SIF=$CONT/quay.io_biocontainers_multiqc:1.23--pyhdfd78af_0.sif
export QUALIMAP_SIF=${CONT}/qualimap_2_3.sif
export MOSDEPTH_SIF=${CONT}/mosdepth_0_3_8.sif
export GATK_SIF=${CONT}/broadinstitute_gatk:4.6.0.0.sif
export SAMTOOLS_SIF=${CONT}/staphb_samtools:1.21.sif
export BWAMEM2_SIF=${WORKING_DIR}/containers/bwa-mem2:2.2.1--hd03093a_5
export BCFTOOLS_SIF=${CONT}/staphb_bcftools:1.17.sif

# Databases
export REFERENCE=/rs1/shares/brc/admin/databases/s_benedicti/Sbenedicti_v2.fasta
export REFERENCE_GZ=${REFERENCE}.gz
export REF_DIR=$(dirname "$REFERENCE")
export DB=/rs1/shares/brc/admin/databases
export ADAPTERS=$DB/adapters/TruSeq3-PE-2.fa

# Output directories
export FASTQC_BEFORE_DIR=$WORKING_DIR/03_FASTQC_BEFORE
export TRIM_DIR=$WORKING_DIR/04_TRIMMOMATIC
export TRIMMED=$TRIM_DIR/trimmed_reads
export UNPAIRED=$TRIM_DIR/unpaired_reads
export FASTQC_AFTER_DIR=$WORKING_DIR/06_FASTQC_AFTER
export BAM_QC_DIR=${WORKING_DIR}/07_BAM_QC

# BAM Dirs
export ANGSD_BAM_DIR=${WORKING_DIR}/05_BWA_MEM2
export GATK_BAM_DIR=${WORKING_DIR}/05_BWA_MEM2/gatk_downstream

# GATK variant calling directories
export HC_DIR=${WORKING_DIR}/08_HAPLOTYPECALLER
export GVCF_DIR=${HC_DIR}/gvcfs
export GENOTYPED_DIR=${WORKING_DIR}/09_GENOTYPED

# Utility functions
function create_dir {
    for dir in "$@"; do
        [[ ! -d "$dir" ]] && mkdir -p "$dir"
    done
}

function lc() { wc -l "$1" | cut -d ' ' -f 1; }

# get_sample_entry: returns the XFILE line for this array index
# Format: SUBDIR/SAMPLE_PREFIX (e.g., Bar_L/Bar_L_01)
function get_sample_entry() {
    sed -n "${LSB_JOBINDEX}p" "${XFILE}"
}

# Convenience: extract just the sample name (Bar_L_01) and subdir (Bar_L)
function get_sample_name() {
    basename "$(get_sample_entry)"
}

function get_sample_subdir() {
    dirname "$(get_sample_entry)"
}
