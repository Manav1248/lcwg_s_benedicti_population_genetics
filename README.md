# S. *benedicti* lcWGS Pop Gen Pipeline

Preprocessing pipeline for low-coverage whole genome sequencing data from *Streblospio benedicti*. Takes raw paired-end Illumina reads through QC, trimming, and alignment to produce analysis-ready BAM files for GATK/ANGSD.

## Pipeline Steps

| Step | Script | What it does |
|------|--------|--------------|
| 00 | `00_index_reference.sh` | Index reference genome (run once) |
| 03 | `03_fastqc_before` | FastQC + MultiQC on raw reads |
| 04 | `04_trimmomatic` | Adapter/quality trimming + post-trim FastQC |
| 05 | `05_bwamem2` | BWA-MEM2 alignment, duplicates flagged (for ANGSD) |
| 05b | `05b_bwamem2_gatk` | BWA-MEM2 alignment, duplicates removed (for GATK) |

## Pipeline File Structure

Each step follows the same pattern:

```
global_config.sh          # Shared paths, containers, helper functions
├── XX_step.config        # Job resources + step-specific paths
├── XX_step_launcher.sh   # Submits the LSF array job
└── XX_step.sh            # Worker script (runs once per sample)
```


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
bash 03_fastqc_before_launcher.sh
bash 04_trimmomatic_launcher.sh
bash 05_bwamem2_launcher.sh
bash 05b_bwamem2_gatk_launcher.sh
```

Each launcher submits an LSF array job, one task per sample. Wait for each step to finish before starting the next.

## Sample List

`full_sample_list.txt` drives all array jobs. One line per sample in `Population/SampleName` format:

```
Bar_L/Bar_L_F01
Bar_L/Bar_L_F02
FL/FL_P_F01
```

## Outputs

- **03_FASTQC_BEFORE/** - Raw read quality reports
- **04_TRIMMOMATIC/** - Trimmed reads (paired + unpaired)
- **05_BWA_MEM2/** - Aligned BAMs with duplicates flagged (`.sorted.markdup.bam`)
- **05_BWA_MEM2/gatk_downstream/** - Aligned BAMs with duplicates removed (`.sorted.dedup.bam`)
- **06_FASTQC_AFTER/** - Post-trim quality reports

## TODO:
- **Qualimap** - mapping rate, insert size, GC bias and duplication on BAMs
- **mosdepth** - window depth-of-coverage in 50k bins (-- by 50000 --no-per-base)

## Requirements

- LSF job scheduler
- Apptainer/Singularity
- Containers: FastQC, Trimmomatic, MultiQC, BWA-MEM2, samtools, qualimap, mosdepth, gatk, angsd

## Data

136 samples across 10 populations from 3 US coasts (Atlantic, Gulf, West). ~8-10X coverage per individual.
