#!/bin/bash
#
# 06_peaks.sh — Identificação de picos de enriquecimento
# Ferramenta: MACS3 3.0.4
#
set -euo pipefail
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/06_peaks.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 6 — Peak calling (MACS3)"

mkdir -p $RESULTS/peaks

CHIP_BAM=$RESULTS/alignment/chip_dedup.bam
CTRL_BAM=$RESULTS/alignment/ctrl_dedup.bam

# MACS3 callpeak
# Parâmetros:
#   -t → arquivo ChIP (tratamento)
#   -c → arquivo controle (input)
#   -f BAM → formato de entrada
#   -g hs → tamanho efetivo do genoma humano
#   -n ctcf → prefixo dos arquivos de saída
#   -q → q-value (FDR) threshold — critério único de significância
#   --call-summits → identifica o ponto exato de máximo de cada pico
#   --nomodel → desativa o modelo de shift (útil quando o modelo automático falha)
#   Nota: sem --nomodel, o MACS3 estima o shift automaticamente a partir dos dados
#
# IMPORTANTE: -p (p-value) e -q (q-value/FDR) são mutuamente exclusivos no
# parser do MACS3 — rodar os dois juntos trava com:
#   error: argument -q/--qvalue: not allowed with argument -p/--pvalue
# Mantemos apenas -q, que é o critério padrão-ouro (controla FDR via
# correção de Benjamini-Hochberg) e atende ao rigor exigido pelos revisores.
echo "[$(date)] Rodando MACS3..."
macs3 callpeak \
    -t $CHIP_BAM \
    -c $CTRL_BAM \
    -f BAM \
    -g $GENOME_SIZE \
    -n ctcf \
    --outdir $RESULTS/peaks \
    -q $QVALUE \
    --call-summits \
    2>&1 | tee $LOGS/06_macs3.log

# Relatório de picos
PEAKS=$RESULTS/peaks/ctcf_peaks.narrowPeak
SUMMITS=$RESULTS/peaks/ctcf_summits.bed

N_PEAKS=$(wc -l < $PEAKS)
echo ""
echo "  Total de picos identificados: $N_PEAKS"
echo "  Arquivo narrowPeak: $PEAKS"
echo "  Arquivo summits:    $SUMMITS"

# Estatísticas dos scores
echo ""
echo "  Distribuição de scores (coluna 5 do narrowPeak):"
awk '{print $5}' $PEAKS | sort -n | \
    awk 'BEGIN{min=9999; max=0; sum=0; count=0}
         {if($1<min)min=$1; if($1>max)max=$1; sum+=$1; count++}
         END{printf "  Min: %d | Max: %d | Média: %.1f | Total: %d\n",
             min, max, sum/count, count}'

echo ""
echo "[$(date)] ETAPA 6 CONCLUÍDA"
