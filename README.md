# S. *benedicti* lcWGS Pop Gen Pipeline

Pipeline for low-coverage whole genome sequencing data from *Streblospio benedicti*. Takes raw paired-end Illumina reads through QC, trimming, alignment, and variant calling to produce a filtered VCF for downstream population genomics.

## Pipeline Steps

| Step | Script | What it does |
|------|--------|--------------|
| 00 | `00_index_reference.sh` | Index reference genome (run once) |
| 03 | `03_fastqc_before` | FastQC + MultiQC on raw reads |
| 04 | `04_trimmomatic` | Adapter/quality trimming + post-trim FastQC |
| 05 | `05_bwamem2` | BWA-MEM2 alignment, duplicates flagged (for ANGSD) |
| 05b | `05b_bwamem2_gatk` | BWA-MEM2 alignment, duplicates removed (for GATK) |
| 07 | `07_bam_qc` | Qualimap + mosdepth on GATK BAMs |
| 08 | `08_haplotypecaller` | Per-sample GVCF calling (GATK HaplotypeCaller, ERC GVCF mode) |
| 09b | `09b_genomicsdb_import` | GenomicsDBImport per chromosome (parallelized, replaces `09_combine_gvcfs`) |
| 10b | `10b_genotype_by_interval` | GenotypeGVCFs per chromosome with `--include-non-variant-sites` (parallelized, replaces `10_genotype_gvcfs`) |
| 11b | `11b_gather_filter.sh` | Gather per-interval VCFs + hard filter SNPs/indels (replaces `11_select_filter_variants`) |

### Parallelized variant calling (steps 09b–11b)

The original single-shot scripts (`09_combine_gvcfs`, `10_genotype_gvcfs`, `11_select_filter_variants`) are retained but too slow for 136 samples across a 701 Mb genome. Steps 09b–11b replace them with a per-chromosome strategy:

- **09b** splits the genome into 12 interval groups (11 chromosomes + 1 scaffolds bundle) and imports all sample GVCFs into a GenomicsDB workspace per interval. Runs as a 12-element array job.
- **10b** runs GenotypeGVCFs against each GenomicsDB workspace. Runs as a 12-element array job.
- **11b** gathers the 12 per-interval VCFs in dictionary order, then runs the same SelectVariants + VariantFiltration hard filtering as the original step 11.

A setup script (`09b_setup_intervals.sh`) creates the interval lists and sample map before submitting.

## Pipeline File Structure

Each step follows the same pattern:
```
global_config.sh          # Shared paths, containers, helper functions
├── XX_step.config        # Job resources + step-specific paths
├── XX_step_launcher.sh   # Submits the LSF array job
└── XX_step.sh            # Worker script (runs once per sample)
```

Standalone jobs (07_bam_qc_multiqc, 11b_gather_filter) use `#BSUB` directives directly and are submitted with `bsub <`.

## Setup

1. Edit paths in `global_config.sh` (project dir, containers, reference, etc.)
2. Generate the sample list:
   ```bash
   bash generate_sample_list.sh /path/to/reads
   ```
3. Index the reference (one time):
   ```bash
   mkdir -p logs && bsub < 00_index_reference.sh
   ```

## Running

From the `scripts/` directory:
```bash
# preprocessing
bash 03_fastqc_before_launcher.sh
bash 04_trimmomatic_launcher.sh
bash 05_bwamem2_launcher.sh
bash 05b_bwamem2_gatk_launcher.sh

# BAM QC
bash 07_bam_qc_launcher.sh
bsub < 07_bam_qc_multiqc.sh

# variant calling
bash 08_haplotypecaller_launcher.sh

# parallelized joint genotyping
bash 09b_setup_intervals.sh
bash 09b_genomicsdb_import_launcher.sh
bash 10b_genotype_by_interval_launcher.sh
bsub < 11b_gather_filter.sh
```

Each launcher submits an LSF array job, one task per sample (or per interval for 09b/10b). Wait for each step to finish before starting the next.

## Sample List

`full_sample_list.txt` drives all array jobs. One line per sample in `Population/SampleName` format:
```
Bar_L/Bar_L_F01
Bar_L/Bar_L_F02
FL/FL_P_F01
```

## Outputs

- **03_FASTQC_BEFORE/** — Raw read quality reports
- **04_TRIMMOMATIC/** — Trimmed reads (paired + unpaired)
- **05_BWA_MEM2/** — Aligned BAMs with duplicates flagged (`.sorted.markdup.bam`)
- **05_BWA_MEM2/gatk_downstream/** — Aligned BAMs with duplicates removed (`.sorted.dedup.bam`)
- **06_FASTQC_AFTER/** — Post-trim quality reports
- **07_BAM_QC/** — Qualimap and mosdepth reports per sample
- **08_HAPLOTYPECALLER/gvcfs/** — Per-sample GVCFs
- **08_HAPLOTYPECALLER/genomicsdb/** — GenomicsDB workspaces per interval
- **09_GENOTYPED/** — Joint-genotyped all-sites VCF
- **09_GENOTYPED/filtered/** — Hard-filtered SNP and indel VCFs (`snps.pass.vcf.gz`, `indels.pass.vcf.gz`)

## Requirements

- LSF job scheduler
- Apptainer/Singularity
- Containers: FastQC, Trimmomatic, MultiQC, BWA-MEM2, samtools, Qualimap, mosdepth, GATK

## Data

136 samples across 11 populations from 3 US coasts (Atlantic, Gulf, West). ~3.6X median coverage per individual (target was 8–10X).
