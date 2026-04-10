#!/bin/bash
#BSUB -J index_reference
#BSUB -n 8
#BSUB -W 02:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o logs/index_ref_%J.out
#BSUB -e logs/index_ref_%J.err

pwd; hostname; date

# paths...
REF_GZ="/rs1/shares/brc/admin/databases/s_benedicti/Sbenedicti_v2.fasta.gz"
REF_DIR="$(dirname "$REF_GZ")"
REF_FA="${REF_DIR}/Sbenedicti_v2.fasta"

BWAMEM2_SIF="/share/ivirus/dhermos/zakas_project/containers/bwa-mem2:2.2.1--hd03093a_5"
SAMTOOLS_SIF="/rs1/shares/brc/admin/containers/images/staphb_samtools:1.21.sif"

module load apptainer

if [[ -f "$REF_FA" ]]; then
    echo "Decompressed reference already exists: ${REF_FA}"
else
    echo "Decompressing reference..."
    gunzip -k "$REF_GZ"
    echo "  Done: $(ls -lh "$REF_FA" | awk '{print $5}')"
fi
echo ""

# Step 2: samtools faidx (creates .fai)
if [[ -f "${REF_FA}.fai" ]]; then
    echo "samtools faidx index already exists: ${REF_FA}.fai"
else
    echo "Running samtools faidx..."
    apptainer exec \
        --bind ${REF_DIR}:${REF_DIR} \
        $SAMTOOLS_SIF \
        samtools faidx "$REF_FA"
    echo "  Done: ${REF_FA}.fai"
fi
echo ""

# Step 3: bwa-mem2 index (creates .0123, .bwt.2bit.64, .ann, .amb, .pac)
if [[ -f "${REF_FA}.bwt.2bit.64" ]]; then
    echo "bwa-mem2 index already exists: ${REF_FA}.bwt.2bit.64"
else
    echo "Running bwa-mem2 index..."
    apptainer exec \
        --bind ${REF_DIR}:${REF_DIR} \
        $BWAMEM2_SIF \
        bwa-mem2 index "$REF_FA"
    echo "  Done."
fi
echo ""

date
