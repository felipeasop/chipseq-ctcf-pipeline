#!/bin/bash

# 02_qc.sh — Controle de qualidade e trimagem de adaptadores
# FastQC 0.12.1
# Trim Galore 2.2.0

set -euo pipefail
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/02_qc.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 2 — Controle de qualidade"

mkdir -p $RESULTS/fastqc/raw
mkdir -p $RESULTS/fastqc/trimmed
mkdir -p $DATA_TRIM

# 2.1 Concatenar FASTQs ChIP
echo "[$(date)] Concatenando FASTQs ChIP..."
cat "${CHIP_FILES[@]}" > $DATA_RAW/chip_raw.fastq.gz
echo "  Total reads brutos ChIP: $(zcat $DATA_RAW/chip_raw.fastq.gz | wc -l | awk '{print $1/4}')"

# 2.2 Concatenar FASTQs controle
echo "[$(date)] Concatenando FASTQs controle..."
cat "${CTRL_FILES[@]}" > $DATA_RAW/ctrl_raw.fastq.gz
echo "  Total reads brutos controle: $(zcat $DATA_RAW/ctrl_raw.fastq.gz | wc -l | awk '{print $1/4}')"

# 2.3 FastQC nos arquivos brutos
echo "[$(date)] Rodando FastQC nos arquivos brutos..."
fastqc \
    $DATA_RAW/chip_raw.fastq.gz \
    $DATA_RAW/ctrl_raw.fastq.gz \
    -o $RESULTS/fastqc/raw \
    -t $THREADS \
    --quiet
echo "  FastQC (bruto) concluído."

# 2.4 Trim Galore - ChIP
# Parâmetros:
#   --quality 20  -> remove bases com Phred < 20
#   --length 36   -> descarta reads < 36bp após trimagem
#   --cores       -> paralelismo
echo "[$(date)] Trim Galore — ChIP..."
trim_galore \
    --quality 20 \
    --length 36 \
    --cores $THREADS \
    $DATA_RAW/chip_raw.fastq.gz \
    -o $DATA_TRIM/
echo "  Trim Galore ChIP concluído."

# 2.5 Trim Galore — Controle
echo "[$(date)] Trim Galore — Controle..."
trim_galore \
    --quality 20 \
    --length 36 \
    --cores $THREADS \
    $DATA_RAW/ctrl_raw.fastq.gz \
    -o $DATA_TRIM/
echo "  Trim Galore controle concluído."

# 2.6 FastQC nos arquivos trimados
echo "[$(date)] Rodando FastQC nos arquivos trimados..."
fastqc \
    $DATA_TRIM/chip_raw_trimmed.fq.gz \
    $DATA_TRIM/ctrl_raw_trimmed.fq.gz \
    -o $RESULTS/fastqc/trimmed \
    -t $THREADS \
    --quiet
echo "  FastQC (trimado) concluído."

# Resumo
echo ""
echo "[$(date)] ETAPA 2 CONCLUÍDA"
echo "  Reads ChIP trimados:     $DATA_TRIM/chip_raw_trimmed.fq.gz"
echo "  Reads controle trimados: $DATA_TRIM/ctrl_raw_trimmed.fq.gz"
echo "  FastQC bruto:    $RESULTS/fastqc/raw/"
echo "  FastQC trimado:  $RESULTS/fastqc/trimmed/"
