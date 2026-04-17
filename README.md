# S. *benedicti* lcWGS Pop Gen Pipeline

Low-coverage whole-genome sequencing pipeline for *Streblospio benedicti*.
Takes raw paired-end Illumina reads through QC, trimming, alignment, and
joint variant calling, producing a hard-filtered SNP + indel VCF for
downstream population genomics.

136 samples, 11 populations, 701 Mb reference, ~3.6X median coverage.

## What it does

Data flow is strictly linear:

```
raw fastq
  -> 03 FastQC before trim
  -> 04 Trimmomatic (+ FastQC after)
  -> 05 / 05b BWA-MEM2 alignment
         05  = duplicates flagged   (BAMs for ANGSD)
         05b = duplicates removed   (BAMs for GATK)
  -> 07 BAM QC (Qualimap + mosdepth + MultiQC)
  -> 08 HaplotypeCaller per sample  (-> per-sample GVCFs)
  -> 09b GenomicsDBImport per chromosome
  -> 10b 10 Mb chunking + GenotypeGVCFs per chunk
         (--include-non-variant-sites for pixy-style diversity)
  -> 11b bcftools concat + hard filter + PASS extraction
         -> snps.pass.vcf.gz, indels.pass.vcf.gz
```

The split at step 05 produces two BAM sets from the same alignments: one
with duplicates flagged (for ANGSD genotype-likelihood workflows) and one
with duplicates removed (for GATK joint calling). Only the GATK path is
run end-to-end here; ANGSD/PCAngsd/FST scripts live in
[scripts/deprecated/](scripts/deprecated/).

## Step reference

| Step | Script                          | What it does                                   |
|------|---------------------------------|------------------------------------------------|
| 00   | `00_index_reference.sh`         | faidx + bwa-mem2 index (once)                  |
| 03   | `03_fastqc_before_launcher.sh`  | FastQC + MultiQC on raw reads                  |
| 04   | `04_trimmomatic_launcher.sh`    | Adapter/quality trim + post-trim FastQC        |
| 05   | `05_bwamem2_launcher.sh`        | Align, dups flagged (ANGSD BAMs)               |
| 05b  | `05b_bwamem2_gatk_launcher.sh`  | Align, dups removed (GATK BAMs)                |
| 07   | `07_bam_qc_launcher.sh`         | Qualimap + mosdepth per sample                 |
| 07   | `07_bam_qc_multiqc.sh`          | MultiQC aggregation (one shot)                 |
| 08   | `08_haplotypecaller_launcher.sh`| Per-sample GVCF calling                        |
| 09b  | `09b_setup_intervals.sh`        | Build interval lists + sample map              |
| 09b  | `09b_genomicsdb_import_launcher.sh` | GenomicsDBImport per chromosome (11 jobs)  |
| 10b  | `10b_setup_chunks.sh`           | Split genome into 10 Mb chunks                 |
| 10b  | `10b_genomicsdb_chunk_launcher.sh` | GenomicsDBImport per chunk                  |
| 10b  | `10b_genotype_chunk_launcher.sh`| GenotypeGVCFs per chunk (all sites)            |
| 11b  | `11b_gather_filter.sh`          | bcftools concat + hard filter + PASS SNPs/indels |

## Layout

```
scripts/
  global_config.sh              paths, containers, helpers
  XX_step.config                per-step resources + paths
  XX_step.sh                    worker (one invocation per array task)
  XX_step_launcher.sh           runs on login node, submits the array
  generate_sample_list.sh       builds full_sample_list.txt from reads/
  deprecated/                   ANGSD/PCAngsd/diversity/FST (not run here)
  recovery/                     one-off fixups for specific samples
```

Standalone jobs (`00_index_reference.sh`, `07_bam_qc_multiqc.sh`,
`11b_gather_filter.sh`) carry `#BSUB` directives inline and are submitted
with `bsub < script.sh`. Array jobs use a launcher + worker pair: run the
launcher with `bash`, and it submits the worker as an LSF array.

## Setup

1. Edit the paths block at the top of `global_config.sh`
   (`WORKING_DIR`, `READS_BASE`, `XFILE`, `PIPELINE_DIR`).
2. Generate the sample list:
   ```
   bash generate_sample_list.sh /path/to/reads
   ```
3. Index the reference (once):
   ```
   mkdir -p logs
   bsub < 00_index_reference.sh
   ```

## Running

From `scripts/`, run each step and wait for it to finish before starting
the next:

```
# preprocessing + alignment
bash 03_fastqc_before_launcher.sh
bash 04_trimmomatic_launcher.sh
bash 05_bwamem2_launcher.sh
bash 05b_bwamem2_gatk_launcher.sh

# BAM QC
bash 07_bam_qc_launcher.sh
bsub < 07_bam_qc_multiqc.sh

# per-sample GVCFs
bash 08_haplotypecaller_launcher.sh

# joint genotyping (chunked)
bash 09b_setup_intervals.sh
bash 09b_genomicsdb_import_launcher.sh
bash 10b_setup_chunks.sh
bash 10b_genomicsdb_chunk_launcher.sh
bash 10b_genotype_chunk_launcher.sh

# filter
bsub < 11b_gather_filter.sh
```

## Sample list format

`full_sample_list.txt` is the array-index key for every step. One line per
sample, `Population/SampleName`:

```
Bar_L/Bar_L_F01
Bar_L/Bar_L_F02
FL/FL_P_F01
```

Reads must live at `${READS_BASE}/${Population}/${SampleName}_R{1,2}.fastq`.

## Outputs

| Directory                                       | Contents                                              |
|-------------------------------------------------|-------------------------------------------------------|
| `03_FASTQC_BEFORE/`                             | Raw-read FastQC + MultiQC                             |
| `04_TRIMMOMATIC/trimmed_reads/`                 | Paired trimmed fastq.gz                               |
| `06_FASTQC_AFTER/`                              | Post-trim FastQC + MultiQC                            |
| `05_BWA_MEM2/`                                  | ANGSD BAMs (`.sorted.markdup.bam`)                    |
| `05_BWA_MEM2/gatk_downstream/`                  | GATK BAMs (`.sorted.dedup.bam`)                       |
| `07_BAM_QC/`                                    | Qualimap + mosdepth + MultiQC per BAM set             |
| `08_HAPLOTYPECALLER/gvcfs/`                     | Per-sample GVCFs                                      |
| `08_HAPLOTYPECALLER/genomicsdb/`                | Per-chromosome GenomicsDB workspaces                  |
| `08_HAPLOTYPECALLER/genomicsdb_chunks/`         | Per-chunk GenomicsDB workspaces                       |
| `09_GENOTYPED/by_chunk/`                        | Per-chunk all-sites VCFs                              |
| `09_GENOTYPED/all_samples.allsites.vcf.gz`      | Merged all-sites VCF                                  |
| `09_GENOTYPED/filtered/snps.pass.vcf.gz`        | Hard-filtered PASS SNPs (**deliverable**)             |
| `09_GENOTYPED/filtered/indels.pass.vcf.gz`      | Hard-filtered PASS indels                             |

## Requirements

- LSF (`bsub` / `$LSB_JOBINDEX`)
- Apptainer / Singularity
- Containers for FastQC, Trimmomatic, MultiQC, BWA-MEM2, samtools,
  Qualimap, mosdepth, GATK, bcftools
