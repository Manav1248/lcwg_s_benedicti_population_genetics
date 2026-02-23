#!/bin/bash
# global_config.sh - shared vars for streb pipeline

export WORKING_DIR=/share/ivirus/dhermos/zakas_project
export READS_BASE=${WORKING_DIR}/reads
export XFILE=${WORKING_DIR}/scripts/full_sample_list.txt
export PIPELINE_DIR=${WORKING_DIR}/scripts

# containers
export CONT=/rs1/shares/brc/admin/containers/images
export APPT=/usr/local/apps/apptainer/1.4.2-1/bin/apptainer
export FASTQC_SIF=$CONT/quay.io_biocontainers_fastqc:0.12.1--hdfd78af_0.sif
export TRIMMOMATIC_SIF=$CONT/quay.io_biocontainers_trimmomatic:0.40--hdfd78af_0.sif
export MULTIQC_SIF=$CONT/quay.io_biocontainers_multiqc:1.23--pyhdfd78af_0.sif

# databases
export DB=/rs1/shares/brc/admin/databases
export ADAPTERS=$DB/adapters/TruSeq3-PE-2.fa
export REFERENCE=/rs1/shares/brc/admin/databases/s_benedicti/Sbenedicti_v2.fasta

# output dirs
export FASTQC_BEFORE_DIR=$WORKING_DIR/03_FASTQC_BEFORE
export TRIM_DIR=$WORKING_DIR/04_TRIMMOMATIC
export TRIMMED=$TRIM_DIR/trimmed_reads
export UNPAIRED=$TRIM_DIR/unpaired_reads
export FASTQC_AFTER_DIR=$WORKING_DIR/06_FASTQC_AFTER

create_dir() { for d in "$@"; do mkdir -p "$d"; done; }
lc() { wc -l < "$1"; }
get_sample_entry() { sed -n "${LSB_JOBINDEX}p" "${XFILE}"; }
get_sample_name() { basename "$(get_sample_entry)"; }
get_sample_subdir() { dirname "$(get_sample_entry)"; }