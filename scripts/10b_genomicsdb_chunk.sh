#!/bin/bash
# 10b_genomicsdb_chunk.sh - import GVCFs into GenomicsDB for one 10Mb chunk
# array job: one per chunk (66 total)

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/10b_chunks.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/10b_chunks.config"

INT_DIR=${HC_DIR}/intervals
SAMPLE_MAP=${INT_DIR}/sample_map.txt
CHUNK_FILE=${INT_DIR}/genotype_chunks.list
DB_DIR=${HC_DIR}/genomicsdb_chunks
TMPDIR=${DB_DIR}/tmp_${LSB_JOBINDEX}

REGION=$(sed -n "${LSB_JOBINDEX}p" "$CHUNK_FILE")
[[ -z "$REGION" ]] && echo "Error: no chunk for index ${LSB_JOBINDEX}" && exit 1
[[ ! -f "$SAMPLE_MAP" ]] && echo "Error: sample map not found" && exit 1

PADDED=$(printf "%04d" $LSB_JOBINDEX)
WORKSPACE="${DB_DIR}/chunk_${PADDED}"

mkdir -p "$DB_DIR" "$TMPDIR"
[[ -d "$WORKSPACE" ]] && rm -rf "$WORKSPACE"

echo "Chunk ${PADDED}: ${REGION}"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "${JOB10B_IMPORT_HEAP} -XX:ParallelGCThreads=2 -Djava.io.tmpdir=${TMPDIR}" \
        GenomicsDBImport \
        --sample-name-map $SAMPLE_MAP \
        --genomicsdb-workspace-path $WORKSPACE \
        -L ${REGION} \
        --reader-threads 4 \
        --batch-size 50

[[ $? -ne 0 ]] && echo "Error: GenomicsDBImport failed for ${REGION}" && rm -rf "$TMPDIR" && exit 1

echo "Workspace chunk_${PADDED}: $(du -sh "$WORKSPACE" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done"; date
