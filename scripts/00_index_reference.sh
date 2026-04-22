#!/bin/bash
#BSUB -J index_reference
#BSUB -n 8
#BSUB -W 02:00
#BSUB -R "span[hosts=1] rusage[mem=16GB]"
#BSUB -o logs/index_ref_%J.out
#BSUB -e logs/index_ref_%J.err

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/global_config.sh" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/global_config.sh"

module load apptainer

if [[ -f "$REFERENCE" ]]; then
    echo "Decompressed reference already exists: ${REFERENCE}"
else
    echo "Decompressing reference..."
    gunzip -k "$REFERENCE_GZ"
    echo "  Done: $(ls -lh "$REFERENCE" | awk '{print $5}')"
fi
echo ""

# Step 2: samtools faidx (creates .fai)
if [[ -f "${REFERENCE}.fai" ]]; then
    echo "samtools faidx index already exists: ${REFERENCE}.fai"
else
    echo "Running samtools faidx..."
    apptainer exec \
        --bind ${REF_DIR}:${REF_DIR} \
        $SAMTOOLS_SIF \
        samtools faidx "$REFERENCE"
    echo "  Done: ${REFERENCE}.fai"
fi
echo ""

# Step 3: bwa-mem2 index (creates .0123, .bwt.2bit.64, .ann, .amb, .pac)
if [[ -f "${REFERENCE}.bwt.2bit.64" ]]; then
    echo "bwa-mem2 index already exists: ${REFERENCE}.bwt.2bit.64"
else
    echo "Running bwa-mem2 index..."
    apptainer exec \
        --bind ${REF_DIR}:${REF_DIR} \
        $BWAMEM2_SIF \
        bwa-mem2 index "$REFERENCE"
    echo "  Done."
fi
echo ""

date
