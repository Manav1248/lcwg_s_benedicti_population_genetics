# Streblospio benedicti lcWGS Pipeline

Preprocessing and variant calling pipeline for low-coverage whole genome sequencing data from *Streblospio benedicti* populations. Produces a hard-filtered GATK VCF callset from raw paired-end Illumina reads.

## Pipeline Order

| Step | Script(s) | What it does |
|------|-----------|--------------|
| 00 | `00_index_reference.sh` | Decompress reference, build bwa-mem2 and samtools faidx indices |
| 03 | `03_fastqc_before` (config/launcher/worker) | Pre-trim FastQC + MultiQC |
| 04 | `04_trimmomatic` (config/launcher/worker) | Adapter/quality trimming + post-trim FastQC + MultiQC |
| 05b | `05b_bwamem2_gatk` (config/launcher/worker) | Align, fixmate, sort, markdup with duplicate removal → `.sorted.dedup.bam` |
| 07 | `07_bam_qc` (config/launcher/worker) + `07_bam_qc_multiqc.sh` | Qualimap + mosdepth on ANGSD and GATK BAMs, then aggregate MultiQC |
| 08 | `08_haplotypecaller` (config/launcher/worker) | Per-sample GVCF generation in ERC GVCF mode |
| 08* | `08_haplotypecaller_by_interval.sh` / `_interval.sh` / `_merge.sh` / `_merge_intervals.sh` | Interval-split rerun for high-coverage samples that exceeded walltime |
| 09 | `09_combine_gvcfs.sh` | Merge per-sample GVCFs into one multi-sample GVCF |
| 10 | `10_genotype_gvcfs.sh` | Joint genotyping with `--include-non-variant-sites` |
| 11 | `11_select_filter_variants.sh` | SNP/indel selection, hard filtering, PASS extraction, diagnostic tables |

Steps 01–02 (sample list generation, renaming) and step 06 (post-trim FastQC) are handled inline or as one-off commands not included here.

## Script Architecture

Steps 03–08 follow a modular pattern:

- **`global_config.sh`** — shared paths, containers, utility functions
- **`{step}.config`** — step-specific variables (job resources, output dirs)
- **`{step}_launcher.sh`** — validates inputs, creates directories, submits array job
- **`{step}.sh`** — worker script executed per sample via LSF array index

Steps 00 and 09–11 are standalone `#BSUB` scripts submitted directly.

## Key Inputs

- **Raw reads**: `reads/{population}/{sample}_R1.fastq` / `_R2.fastq`
- **Sample list**: `scripts/full_sample_list.txt` — one entry per line as `SUBDIR/SAMPLE_NAME` (e.g., `Bar_L/Bar_L_01`)
- **Reference**: `Sbenedicti_v2.fasta` at `/rs1/shares/brc/admin/databases/s_benedicti/`

## Key Outputs

- **GATK BAMs**: `05_BWA_MEM2/gatk_downstream/{pop}/{sample}.sorted.dedup.bam`
- **Per-sample GVCFs**: `08_HAPLOTYPECALLER/gvcfs/{pop}/{sample}.g.vcf.gz`
- **Combined GVCF**: `08_HAPLOTYPECALLER/all_samples.g.vcf.gz`
- **Final VCFs**: `09_GENOTYPED/filtered/snps.pass.vcf.gz`, `indels.pass.vcf.gz`
- **Diagnostic tables**: `09_GENOTYPED/filtered/snps.raw.table`, `indels.raw.table`

## Dependencies

- **Scheduler**: LSF (`bsub`)
- **Containers**: Apptainer (all tools run in containers)
  - FastQC 0.12.1, Trimmomatic 0.40, MultiQC 1.23
  - BWA-MEM2 2.2.1, Samtools 1.21
  - Qualimap 2.3, mosdepth 0.3.8
  - GATK 4.6.0.0

## Notes

- 136 samples across 11 populations (Atlantic, Gulf, West coast)
- Median coverage ~3.6X after duplicate removal
- `--include-non-variant-sites` in GenotypeGVCFs retains invariant sites for downstream diversity statistics
- Hard filtering follows GATK best practices for non-model organisms (see below)

## Hard Filtering Rationale

GATK's preferred filtering method (VQSR) requires a known truth set of validated variants to train its model — something that doesn't exist for *S. benedicti*. Hard filtering is the recommended alternative: each variant is evaluated against fixed annotation thresholds and tagged PASS or filtered.

SNP filters applied: QD < 2.0, FS > 60.0, MQ < 40.0, MQRankSum < -12.5, ReadPosRankSum < -8.0, SOR > 3.0. Indel filters: QD < 2.0, FS > 200.0, ReadPosRankSum < -20.0, SOR > 10.0. These are the GATK-recommended defaults for hard filtering.

What the annotations measure:
- **QD** (QualByDepth) — variant quality normalized by depth; low values suggest a weak call
- **FS** (FisherStrand) — strand bias via Fisher's exact test; high values indicate reads supporting the variant come disproportionately from one strand
- **MQ** (MappingQuality) — root mean square mapping quality; low values mean reads don't map confidently
- **MQRankSum** — compares mapping quality of reads supporting ref vs alt alleles; large negative values indicate alt-supporting reads map poorly
- **ReadPosRankSum** — compares position within reads for ref vs alt alleles; large negative values indicate alt alleles cluster at read ends (often artifacts)
- **SOR** (StrandOddsRatio) — another strand bias measure, more robust than FS for high coverage

These thresholds are GATK's generic defaults, calibrated primarily on high-coverage human data. They serve as a reasonable first-pass baseline but are not tuned to this organism or coverage depth. Diagnostic tables (`snps.raw.table`, `indels.raw.table`) contain per-site annotation values for every variant before filtering, so that distributions can be plotted and thresholds adjusted in future work if needed
- Three high-coverage samples (Gal_L_F09, LBA_L_F01, LBA_L_F03) required interval-split HaplotypeCaller runs
