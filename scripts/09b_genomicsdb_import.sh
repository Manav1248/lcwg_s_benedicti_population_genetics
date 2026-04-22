#!/bin/bash
# 09b_genomicsdb_import.sh - import per-sample GVCFs into GenomicsDB for one chromosome
# array job: one job per chromosome (11 total)

pwd; hostname; date

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
[[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/09b_genomicsdb_import.config" ]] && SCRIPT_DIR="${PIPELINE_DIR}"
source "${SCRIPT_DIR}/09b_genomicsdb_import.config"

INT_DIR=${HC_DIR}/intervals
SAMPLE_MAP=${INT_DIR}/sample_map.txt
DB_DIR=${HC_DIR}/genomicsdb
TMPDIR=${DB_DIR}/tmp_${LSB_JOBINDEX}

# which chromosome is this job?
GROUP=$(sed -n "${LSB_JOBINDEX}p" "${INT_DIR}/interval_groups.txt")
[[ -z "$GROUP" ]] && echo "Error: no interval group for index ${LSB_JOBINDEX}" && exit 1

INTERVAL_LIST="${INT_DIR}/${GROUP}.list"
WORKSPACE="${DB_DIR}/${GROUP}"

[[ ! -f "$INTERVAL_LIST" ]] && echo "Error: interval list not found: $INTERVAL_LIST" && exit 1
[[ ! -f "$SAMPLE_MAP" ]] && echo "Error: sample map not found: $SAMPLE_MAP" && exit 1

mkdir -p "$DB_DIR" "$TMPDIR"

# clean up workspace from any failed prior run
[[ -d "$WORKSPACE" ]] && rm -rf "$WORKSPACE"

echo "Interval group: ${GROUP} (index ${LSB_JOBINDEX})"
echo "Samples: $(wc -l < "$SAMPLE_MAP")"

module load apptainer

apptainer exec \
    --bind ${WORKING_DIR}:${WORKING_DIR},${REF_DIR}:${REF_DIR},${TMPDIR}:${TMPDIR} \
    $GATK_SIF \
    gatk --java-options "${JOB09B_HEAP} -XX:ParallelGCThreads=${JOB09B_GC_THREADS} -Djava.io.tmpdir=${TMPDIR}" \
        GenomicsDBImport \
        --sample-name-map $SAMPLE_MAP \
        --genomicsdb-workspace-path $WORKSPACE \
        -L $INTERVAL_LIST \
        --reader-threads ${JOB09B_READER_THREADS} \
        --batch-size ${JOB09B_BATCH_SIZE} \
        --merge-input-intervals

[[ $? -ne 0 ]] && echo "Error: GenomicsDBImport failed for ${GROUP}" && rm -rf "$TMPDIR" && exit 1
[[ ! -d "$WORKSPACE" ]] && echo "Error: workspace missing for ${GROUP}" && rm -rf "$TMPDIR" && exit 1

echo "GenomicsDB workspace for ${GROUP}: $(du -sh "$WORKSPACE" | cut -f1)"
rm -rf "$TMPDIR"
echo "Done"; date
