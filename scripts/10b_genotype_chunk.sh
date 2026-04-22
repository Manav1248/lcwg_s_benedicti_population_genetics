#!/bin/bash
# 10b_genotype_chunk.sh - genotype one 10Mb chunk from its own GenomicsDB workspace
# array job: one per chunk (66 total)

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/10b_chunks.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/10b_chunks.config"

INT_DIR=${HC_DIR}/intervals
CHUNK_FILE=${INT_DIR}/genotype_chunks.list
DB_DIR=${HC_DIR}/genomicsdb_chunks
OUTDIR=${GENOTYPED_DIR}/by_chunk
TMPDIR=${OUTDIR}/tmp_${LSB_JOBINDEX}

REGION=$(sed -n "${LSB_JOBINDEX}p" "$CHUNK_FILE")
[[ -z "$REGION" ]] && echo "Error: no chunk for index ${LSB_JOBINDEX}" && exit 1

PADDED=$(printf "%04d" $LSB_JOBINDEX)
WORKSPACE="${DB_DIR}/chunk_${PADDED}"
OUTPUT="${OUTDIR}/chunk_${PADDED}.vcf.gz"

[[ ! -d "$WORKSPACE" ]] && echo "Error: workspace not found: $WORKSPACE" && exit 1

mkdir -p "$OUTDIR" "$TMPDIR"

echo "Chunk ${PADDED}: ${REGION}"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "${JOB10B_GENO_HEAP} -XX:ParallelGCThreads=${JOB10B_GENO_GC_THREADS} -Djava.io.tmpdir=${TMPDIR}" \
        GenotypeGVCFs \
        -R $REFERENCE \
        -V gendb://${WORKSPACE} \
        -L ${REGION} \
        -O $OUTPUT \
        --include-non-variant-sites \
        --genomicsdb-shared-posixfs-optimizations true

[[ $? -ne 0 ]] && echo "Error: GenotypeGVCFs failed for ${REGION}" && rm -rf "$TMPDIR" && exit 1

echo "Chunk ${PADDED}: $(du -h "$OUTPUT" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done"; date
