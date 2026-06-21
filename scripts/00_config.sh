#!/bin/bash

BASE_DIR=~/Projetos/chipseq-analysis

DATA_RAW=$BASE_DIR/data/raw
DATA_TRIM=$BASE_DIR/data/trimmed
GENOME_DIR=$BASE_DIR/genome
GENOME_INDEX=$BASE_DIR/genome/index/GRCh38
GENOME_FA=$BASE_DIR/genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa
GENOME_SIZES=$BASE_DIR/genome/GRCh38.chrom.sizes
RESULTS=$BASE_DIR/results
LOGS=$BASE_DIR/logs

# https://www.encodeproject.org/experiments/ENCSR921ERP/
# ChIP = reads de imunoprecipitação com anticorpo anti-CTCF
# Control = reads de input (sem anticorpo)

# Arquivos ChIP do experimento ENCSR921ERP (CTCF em Calu-3)
# Bibliotecas ENCLB483NAC e ENCLB214ERW
CHIP_FILES=(
    $DATA_RAW/ENCFF044QUQ.fastq.gz
    $DATA_RAW/ENCFF454WMC.fastq.gz
    $DATA_RAW/ENCFF995QNE.fastq.gz
    $DATA_RAW/ENCFF125DVB.fastq.gz
    $DATA_RAW/ENCFF571YOT.fastq.gz
    $DATA_RAW/ENCFF441YGQ.fastq.gz
    $DATA_RAW/ENCFF406AMF.fastq.gz
    $DATA_RAW/ENCFF183UJY.fastq.gz
    $DATA_RAW/ENCFF598BQY.fastq.gz
    $DATA_RAW/ENCFF496JHX.fastq.gz
    $DATA_RAW/ENCFF103DVR.fastq.gz
    $DATA_RAW/ENCFF591HEE.fastq.gz
    $DATA_RAW/ENCFF441SXK.fastq.gz
    $DATA_RAW/ENCFF827VZG.fastq.gz
    $DATA_RAW/ENCFF251QAS.fastq.gz
    $DATA_RAW/ENCFF785NZO.fastq.gz
)

# Arquivos controle experimento ENCSR871UJG
# Biblioteca ENCLB030UCW + ENCLB489EVC
CTRL_FILES=(
    $DATA_RAW/ctrl/ENCFF245IRU.fastq.gz
    $DATA_RAW/ctrl/ENCFF750SYN.fastq.gz
    $DATA_RAW/ctrl/ENCFF912UIM.fastq.gz
    $DATA_RAW/ctrl/ENCFF223CTC.fastq.gz
    $DATA_RAW/ctrl/ENCFF676OGI.fastq.gz
    $DATA_RAW/ctrl/ENCFF171MPI.fastq.gz
    $DATA_RAW/ctrl/ENCFF323BCA.fastq.gz
    $DATA_RAW/ctrl/ENCFF758ZCP.fastq.gz
    $DATA_RAW/ctrl/ENCFF064TYG.fastq.gz
    $DATA_RAW/ctrl/ENCFF126YWX.fastq.gz
    $DATA_RAW/ctrl/ENCFF394PHP.fastq.gz
    $DATA_RAW/ctrl/ENCFF868HRX.fastq.gz
    $DATA_RAW/ctrl/ENCFF778HMD.fastq.gz
    $DATA_RAW/ctrl/ENCFF284ETL.fastq.gz
    $DATA_RAW/ctrl/ENCFF805AAC.fastq.gz
    $DATA_RAW/ctrl/ENCFF838CMF.fastq.gz
    $DATA_RAW/ctrl/ENCFF274HZZ.fastq.gz
    $DATA_RAW/ctrl/ENCFF751THT.fastq.gz
    $DATA_RAW/ctrl/ENCFF966SRT.fastq.gz
    $DATA_RAW/ctrl/ENCFF069NYT.fastq.gz
)

# Parâmetros de alinhamento
THREADS=10         # Número de threads
MAPQ=30            # Qualidade mínima de mapeamento

# Parâmetros MACS3
PVALUE=1e-5
QVALUE=0.01
GENOME_SIZE=hs     # Homo sapiens

# Parâmetros MEME/STREME
MOTIF_WIDTH=19     # Largura do motivo CTCF
PEAK_EXTENSION=100 # Extensão em bp ao redor do summit

# Banco JASPAR
JASPAR=$BASE_DIR/results/tomtom/JASPAR2024_CORE_non-redundant_pfms_meme.txt

# Pasta tmp
export TMPDIR=$BASE_DIR/tmp
mkdir -p "$TMPDIR"

echo "Configuração carregada com sucesso."
