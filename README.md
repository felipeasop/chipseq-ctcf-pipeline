# ChIP-seq CTCF Pipeline — Motif Discovery Benchmarking

Reproducible Bash pipeline for ChIP-seq analysis with systematic benchmarking
of motif discovery models (OOPS, ZOOPS, STREME) applied to CTCF data.

Companion code for the paper:
> **Benchmarking Motif Discovery Models for Human ChIP-seq Data:
> OOPS, ZOOPS, and STREME Applied to CTCF**
> Submitted to BRACIS/ENIAC 2026.

---

## Dataset

| Field | Value |
|---|---|
| ENCODE experiment | [ENCSR921ERP](https://www.encodeproject.org/experiments/ENCSR921ERP/) |
| Target | CTCF |
| Cell line | *H. sapiens* Calu-3 |
| Platform | Illumina NextSeq 500 |
| Read type | SE76 (76-nt single-end) |
| ChIP libraries | ENCLB483NAC, ENCLB214ERW (16 FASTQ files) |
| Control libraries | ENCLB030UCW, ENCLB489EVC (20 FASTQ files) |
| Reference genome | GRCh38 (Ensembl release 112) |

---

## Tool Versions

| Tool | Version |
|---|---|
| FastQC | 0.12.1 |
| Trim Galore | 2.2.0 |
| Bowtie2 | 2.5.5 |
| SAMtools | 1.23.1 |
| Picard | 3.4.0 |
| MACS3 | 3.0.4 |
| BEDTools | 2.31.1 |
| MEME Suite (MEME/STREME/TOMTOM) | 5.5.9 |

---

## Requirements

- Linux (tested on CachyOS / kernel 7.0.11)
- [micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
- ~150 GB disk space (raw data + genome + results)

---

## Setup

```bash
# 1. Clone the repository
git clone git@github.com:felipeasop/chipseq-ctcf-pipeline.git
cd chipseq-ctcf-pipeline

# 2. Create and activate the environment
micromamba env create -f environment.yml
micromamba activate chipseq

# 3. Edit the base directory in the config script
nano scripts/00_config.sh   # set BASE_DIR to your local path
```

---

## Running the Pipeline

Each script corresponds to one analysis step and can be run independently
or in sequence:

```bash
bash scripts/01_download.sh     # Download FASTQ files from ENCODE
bash scripts/02_qc.sh           # FastQC + Trim Galore
bash scripts/03_index_genome.sh # Index GRCh38 with Bowtie2
bash scripts/04_align.sh        # Align reads (Bowtie2) + sort/index (SAMtools)
bash scripts/05_dedup.sh        # Mark PCR duplicates (Picard)
bash scripts/06_peaks.sh        # Peak calling (MACS3)
bash scripts/07_sequences.sh    # Extract peak sequences (BEDTools)
bash scripts/08_motifs.sh       # Motif discovery: MEME OOPS, ZOOPS, STREME
bash scripts/09_stratify.sh     # Peak stratification by MACS3 score quantile
bash scripts/10_tomtom.sh       # PWM comparison against JASPAR 2024 (TOMTOM)
```

All logs are saved to `logs/`. All results are saved to `results/`.

---

## Pipeline Overview

```
Raw FASTQs (ENCODE)
    └─► FastQC + Trim Galore (QC)
            └─► Bowtie2 (alignment to GRCh38)
                    └─► SAMtools (BAM sorting/indexing)
                            └─► Picard (duplicate marking)
                                    └─► MACS3 (peak calling)
                                            └─► BEDTools (sequence extraction)
                                                    └─► MEME OOPS  ─┐
                                                        MEME ZOOPS  ├─► TOMTOM vs JASPAR 2024
                                                        STREME      ─┘
                                                    └─► Peak stratification (top 10/25/50/100%)
```

---

## Key Parameters

| Parameter | Value | Script |
|---|---|---|
| Trim quality threshold | Phred ≥ 20 | `02_qc.sh` |
| Minimum read length | 36 bp | `02_qc.sh` |
| Alignment mode | `--very-sensitive -N 1 -L 20` | `04_align.sh` |
| Minimum MAPQ | 30 | `04_align.sh` |
| Peak FDR threshold | q ≤ 0.01 | `06_peaks.sh` |
| Summit extension | ±100 bp | `07_sequences.sh` |
| Motif width | 19 nt | `08_motifs.sh` |
| Background model | Markov order-1 (`fasta-get-markov`) | `08_motifs.sh` |
| TOMTOM distance | Pearson correlation | `10_tomtom.sh` |
| JASPAR database | 2024 CORE non-redundant | `10_tomtom.sh` |

---

## Repository Structure

```
.
├── environment.yml       # Pinned conda/micromamba environment
├── scripts/
│   ├── 00_config.sh      # Central configuration (paths, parameters)
│   ├── 01_download.sh    # ENCODE FASTQ download
│   ├── 02_qc.sh          # Quality control and trimming
│   ├── 03_index_genome.sh# Genome indexing
│   ├── 04_align.sh       # Read alignment
│   ├── 05_dedup.sh       # Duplicate marking
│   ├── 06_peaks.sh       # Peak calling
│   ├── 07_sequences.sh   # Sequence extraction
│   ├── 08_motifs.sh      # Motif discovery (OOPS, ZOOPS, STREME)
│   ├── 09_stratify.sh    # Peak stratification analysis
│   └── 10_tomtom.sh      # TOMTOM vs JASPAR comparison
└── README.md
```

---

## License

MIT License. See `LICENSE` for details.
