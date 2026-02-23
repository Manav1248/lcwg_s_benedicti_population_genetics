#!/bin/bash
#BSUB -J index_reference
#BSUB -n 8
#BSUB -W 02:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o logs/index_ref_%J.out
#BSUB -e logs/index_ref_%J.err
# Index reference genome (run once before alignment)

pwd; hostname; date

REF_GZ="/rs1/shares/brc/admin/databases/s_benedicti/Sbenedicti_v2.fasta.gz"
REF_DIR="$(dirname "$REF_GZ")"
REF_FA="${REF_DIR}/Sbenedicti_v2.fasta"
BWAMEM2_SIF="/share/ivirus/dhermos/zakas_project/containers/bwa-mem2:2.2.1--hd03093a_5"
SAMTOOLS_SIF="/rs1/shares/brc/admin/containers/images/staphb_samtools:1.21.sif"

module load apptainer

# decompress
[[ ! -f "$REF_FA" ]] && gunzip -k "$REF_GZ"

# samtools faidx
[[ ! -f "${REF_FA}.fai" ]] && \
    apptainer exec --bind ${REF_DIR}:${REF_DIR} $SAMTOOLS_SIF samtools faidx "$REF_FA"

# bwa-mem2 index
[[ ! -f "${REF_FA}.bwt.2bit.64" ]] && \
    apptainer exec --bind ${REF_DIR}:${REF_DIR} $BWAMEM2_SIF bwa-mem2 index "$REF_FA"