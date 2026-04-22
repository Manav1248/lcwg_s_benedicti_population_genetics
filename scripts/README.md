# *Streblospio benedicti* Low-Coverage WGS Population Genetics Pipeline

GATK-based variant calling pipeline for low-coverage whole-genome sequencing data.  
Designed for LSF (bsub) HPC environments using Apptainer containers. Container links are on the Hazel cluster under the BRC containers/images dir.

---

## Quick Start

**1. Edit `global_config.sh`** — the only file you need to change to set up a new project:

```bash
export WORKING_DIR=/path/to/your/project
export READS_BASE=/path/to/raw/reads
export XFILE=/path/to/your/sample_list.txt
export PIPELINE_DIR=/path/to/these/scripts
```

**2. Generate your sample list** (if needed):

```bash
bash generate_sample_list.sh <reads_dir> <output_file>
```

Each line in `XFILE` must be `POPULATION/SAMPLE_PREFIX` (e.g., `Bar_L/Bar_L_01`).

**3. Run steps in order** using the launchers below.

---

## Pipeline Steps

### Setup (run once before the pipeline)

| Script | Purpose |
|--------|---------|
| `00_index_reference.sh` | Decompress reference, create .fai and bwa-mem2 index |

Submit with: `bsub < 00_index_reference.sh`

---

### Step 03 — FastQC (pre-trim)
```bash
bash 03_fastqc_before_launcher.sh
```

---

### Step 04 — Trimmomatic + post-trim FastQC
```bash
bash 04_trimmomatic_launcher.sh
```

---

### Step 05 — Alignment (ANGSD mode — duplicates flagged)
```bash
bash 05_bwamem2_launcher.sh
```

### Step 05b — Alignment (GATK mode — duplicates removed)
```bash
bash 05b_bwamem2_gatk_launcher.sh
```

---

### Step 07 — BAM QC (Qualimap + mosdepth)
```bash
bash 07_bam_qc_launcher.sh
```

Once the array finishes, aggregate results:
```bash
bsub < 07_bam_qc_multiqc.sh
```

---

### Step 08 — HaplotypeCaller (per sample × chromosome)
```bash
bash 08_haplotypecaller_launcher.sh
```

Once all jobs finish, merge per-chromosome GVCFs:
```bash
bash 08_haplotypecaller_merge_intervals.sh
```

---

### Step 09b — GenomicsDBImport (per chromosome)

First, create interval lists and sample map:
```bash
bash 09b_setup_intervals.sh
```

Then submit:
```bash
bash 09b_genomicsdb_import_launcher.sh
```

---

### Step 10b — Genotype GVCFs (10 Mb chunks)

First, generate the chunk list from the reference:
```bash
bash 10b_setup_chunks.sh
```

Then run GenomicsDBImport and GenotypeGVCFs in order:
```bash
bash 10b_genomicsdb_chunk_launcher.sh
# wait for completion
bash 10b_genotype_chunk_launcher.sh
```

---

### Step 11b — Gather chunks into all-sites VCF
```bash
bash 11b_gather_launcher.sh
```

Output: `${GENOTYPED_DIR}/all_samples.allsites.vcf.gz`

---

### Step 12b — Filter SNPs
```bash
bash 12b_filter_snps_launcher.sh
```

Outputs (in `${GENOTYPED_DIR}/filtered/`):
- `snps.raw.vcf.gz` — unfiltered SNPs
- `snps.filtered.vcf.gz` — hard-filtered (FILTER tag applied)
- `snps.pass.vcf.gz` — PASS sites only
- `snps.raw.table` — quality score table for diagnostic plots

### Step 13b — Filter Indels
```bash
bash 13b_filter_indels_launcher.sh
```

Same output structure as 12b for indels.

---

## Tuning

All job resources and tool parameters live in step config files. Edit these if jobs time out, run out of memory, or you want to adjust tool behavior. **Do not edit the `.sh` scripts directly.**

| Config | Controls |
|--------|---------|
| `03_fastqc_before.config` | FastQC job resources |
| `04_trimmomatic.config` | Trimmomatic resources, adapter/quality parameters, Java heap |
| `05_bwamem2.config` | BWA-MEM2 resources, samtools sort threads |
| `05b_bwamem2_gatk.config` | Same as 05 for GATK-mode alignment |
| `07_bam_qc.config` | Qualimap/mosdepth resources and parameters |
| `08_haplotypecaller.config` | HaplotypeCaller resources, Java heap, GC threads, pair-HMM threads |
| `09b_genomicsdb_import.config` | GenomicsDBImport resources, reader threads, batch size |
| `10b_chunks.config` | Chunk size, GenomicsDB/GenotypeGVCFs resources |
| `11b_gather.config` | Gather resources, parallel chunk-fix settings |
| `12b_filter_snps.config` | SNP filter resources and hard-filter thresholds |
| `13b_filter_indels.config` | Indel filter resources and hard-filter thresholds |

---

## Repository Structure

```
scripts/
├── global_config.sh              # ← EDIT THIS for new projects
├── chromosome_list.txt           # 11 chromosomes in dict order (fixed for this reference)
├── generate_sample_list.sh       # utility: build XFILE from reads directory
│
├── 00_index_reference.sh
│
├── 03_fastqc_before.config / _launcher.sh / .sh
├── 04_trimmomatic.config / _launcher.sh / .sh
├── 05_bwamem2.config / _launcher.sh / .sh
├── 05b_bwamem2_gatk.config / _launcher.sh / .sh
│
├── 07_bam_qc.config / _launcher.sh / .sh
├── 07_bam_qc_multiqc.sh
│
├── 08_haplotypecaller.config
├── 08_haplotypecaller_launcher.sh
├── 08_haplotypecaller_interval.sh
├── 08_haplotypecaller_merge_intervals.sh
├── 08_haplotypecaller_merge.sh
│
├── 09b_setup_intervals.sh
├── 09b_genomicsdb_import.config / _launcher.sh / .sh
│
├── 10b_setup_chunks.sh
├── 10b_chunks.config
├── 10b_genomicsdb_chunk_launcher.sh / .sh
├── 10b_genotype_chunk_launcher.sh / .sh
│
├── 11b_gather.config / _launcher.sh / .sh
├── 12b_filter_snps.config / _launcher.sh / .sh
├── 13b_filter_indels.config / _launcher.sh / .sh
│
├── deprecated/                   # old scripts, kept for reference
└── recovery/                     # one-off scripts from the original run
```

---

## Notes

- Steps 12b and 13b both read from `all_samples.allsites.vcf.gz` and can be re-run independently — useful when tuning filter thresholds.
- Hard-filter thresholds follow GATK best practices. Adjust in `12b_filter_snps.config` and `13b_filter_indels.config`.
- `chromosome_list.txt` is in sequence dictionary order (lexicographic). Do not change the order — it must match the reference dictionary for `GatherVcfs`.
- All containers are pulled from the shared HPC image repository (`$CONT` = `/rs1/shares/brc/admin/containers/images`).
