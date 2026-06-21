#!/bin/bash
#
# 04_align.sh — Alinhamento ao genoma de referência
# Ferramentas: Bowtie2 2.5.5, SAMtools 1.23.1
#
set -euo pipefail
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/04_align.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 4 — Alinhamento"

mkdir -p $RESULTS/alignment

# Função de alinhamento reutilizável
# Argumentos: $1=nome (chip|ctrl), $2=arquivo FASTQ trimado
# Justificativa dos parâmetros Bowtie2:
#   --very-sensitive → aumenta sensibilidade (mais tentativas de alinhamento)
#   -N 1            → permite 1 mismatch na seed region
#   -L 20           → tamanho da seed region
#   -x              → prefixo do índice
#   --no-unal       → não reporta reads não alinhados (reduz tamanho do SAM)
align_sample() {
    local NAME=$1
    local FASTQ=$2
    local SAM=$RESULTS/alignment/${NAME}.sam
    local BAM=$RESULTS/alignment/${NAME}_sorted.bam

    echo "[$(date)] Alinhando $NAME..."
    bowtie2 \
        -p $THREADS \
        --very-sensitive \
        -N 1 \
        -L 20 \
        -x $GENOME_INDEX \
        -U $FASTQ \
        --no-unal \
        -S $SAM \
        2> $LOGS/${NAME}_bowtie2_stats.txt

    echo "  Taxa de alinhamento $NAME:"
    grep "overall alignment rate" $LOGS/${NAME}_bowtie2_stats.txt

    # Converter SAM → BAM, ordenar e indexar
    echo "[$(date)] Convertendo e ordenando $NAME..."
    samtools view -bS -q $MAPQ $SAM | \
        samtools sort -@ $THREADS -o $BAM

    samtools index $BAM

    # Estatísticas de alinhamento
    samtools flagstat $BAM > $LOGS/${NAME}_flagstat.txt
    echo "  Flagstat salvo: $LOGS/${NAME}_flagstat.txt"

    # Remover SAM (economizar espaço)
    rm $SAM
    echo "  $NAME concluído → $BAM"
}

# 4.1 Alinhar ChIP
# align_sample "chip" $DATA_TRIM/chip_raw_trimmed.fq.gz

# 4.2 Alinhar Controle
align_sample "ctrl" $DATA_TRIM/ctrl_raw_trimmed.fq.gz

echo ""
echo "[$(date)] ETAPA 4 CONCLUÍDA"
echo "  ChIP BAM:  $RESULTS/alignment/chip_sorted.bam"
echo "  Ctrl BAM:  $RESULTS/alignment/ctrl_sorted.bam"
echo "  Logs:      $LOGS/chip_bowtie2_stats.txt"
echo "             $LOGS/ctrl_bowtie2_stats.txt"
