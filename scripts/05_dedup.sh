#!/bin/bash
#
# 05_dedup.sh — Marcação de duplicatas de PCR
# Ferramenta: Picard 3.4.0
#
set -euo pipefail
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/05_dedup.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 5 — Remoção de duplicatas PCR"

# Função de deduplicação
# REMOVE_DUPLICATES=false → apenas marca, não remove
# (MACS3 pode usar reads marcados para estimar taxa de duplicação)
dedup_sample() {
    local NAME=$1
    local IN=$RESULTS/alignment/${NAME}_sorted.bam
    local OUT=$RESULTS/alignment/${NAME}_dedup.bam
    local METRICS=$LOGS/${NAME}_picard_metrics.txt

    echo "[$(date)] Picard MarkDuplicates — $NAME..."
    picard MarkDuplicates \
        -I $IN \
        -O $OUT \
        -M $METRICS \
        --REMOVE_DUPLICATES false \
        --ASSUME_SORTED true \
        --VALIDATION_STRINGENCY LENIENT \
        2>> $LOG

    samtools index $OUT

    # Relatório de duplicatas
    echo "  Taxa de duplicatas $NAME:"
    grep -A 1 "PERCENT_DUPLICATION" $METRICS | tail -1 | \
        awk '{printf "  Duplicatas: %.2f%%\n", $9*100}'

    echo "  $NAME deduplicado → $OUT"
}

# 5.1 Deduplicar ChIP e Controle
# dedup_sample "chip"
dedup_sample "ctrl"

echo ""
echo "[$(date)] ETAPA 5 CONCLUÍDA"
echo "  ChIP dedup: $RESULTS/alignment/chip_dedup.bam"
echo "  Ctrl dedup: $RESULTS/alignment/ctrl_dedup.bam"
echo "  Métricas:   $LOGS/chip_picard_metrics.txt"
echo "              $LOGS/ctrl_picard_metrics.txt"
