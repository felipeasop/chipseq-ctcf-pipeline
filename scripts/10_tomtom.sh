#!/bin/bash
#
# 10_tomtom.sh — Comparação dos motivos com o banco JASPAR 2024
# Ferramenta: TOMTOM (MEME Suite 5.5.9)
#
set -euo pipefail
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/10_tomtom.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 10 — Comparação TOMTOM × JASPAR"

MOTIFS=$RESULTS/motifs
TOMTOM_OUT=$RESULTS/tomtom

mkdir -p $TOMTOM_OUT

if [ ! -s "$JASPAR" ]; then
    echo "[$(date)] Baixando JASPAR 2024..."
    wget -c -O $JASPAR \
        "https://jaspar.elixir.no/download/data/2024/CORE/JASPAR2024_CORE_non-redundant_pfms_meme.txt"

    if [ ! -s "$JASPAR" ]; then
        echo "  [ERRO] Download do JASPAR falhou ou arquivo ficou vazio."
        echo "  Verifique manualmente: $JASPAR"
        exit 1
    fi
    echo "  JASPAR baixado: $(ls -lh $JASPAR | awk '{print $5}')"
else
    echo "  JASPAR já existe ($(ls -lh $JASPAR | awk '{print $5}')), pulando download."
fi

run_tomtom() {
    local LABEL=$1
    local QUERY=$2
    local OUTDIR=$TOMTOM_OUT/${LABEL}

    if [ ! -f "$QUERY" ]; then
        echo "  [AVISO] Arquivo não encontrado: $QUERY — pulando $LABEL"
        return
    fi

    echo "[$(date)] TOMTOM — $LABEL..."
    tomtom \
        -o $OUTDIR \
        -no-ssc \
        -verbosity 1 \
        -min-overlap 5 \
        -dist pearson \
        -thresh 0.05 \
        $QUERY \
        $JASPAR \
        2>> $LOG

    if [ -f "$OUTDIR/tomtom.tsv" ]; then
        echo "  Top match $LABEL:"
        awk 'NR==2 {printf "    TF: %s | p-value: %s | E-value: %s | q-value: %s\n",
            $2, $4, $5, $6}' $OUTDIR/tomtom.tsv
        awk -v label="$LABEL" 'NR==2 {
            print label","$2","$4","$5","$6
        }' $OUTDIR/tomtom.tsv >> $LOGS/tomtom_comparison.csv
    fi
}

echo "experimento,tf_match,pvalue,evalue,qvalue" > $LOGS/tomtom_comparison.csv

run_tomtom "meme_oops"        $MOTIFS/meme_oops/meme.txt
run_tomtom "meme_oops_markov" $MOTIFS/meme_oops_markov/meme.txt
run_tomtom "meme_zoops"       $MOTIFS/meme_zoops/meme.txt
run_tomtom "streme"           $MOTIFS/streme/streme.txt

for PCT in 10 25 50 100; do
    run_tomtom "streme_top${PCT}" $MOTIFS/streme_top${PCT}/streme.txt
done

echo ""
echo "[$(date)] TABELA COMPARATIVA FINAL"
echo ""
printf "%-25s | %-10s | %-12s | %-12s | %-12s\n" \
    "Experimento" "TF Match" "p-value" "E-value" "q-value"
printf "%s\n" "$(printf '%.0s-' {1..80})"

while IFS=',' read -r label tf pval eval qval; do
    [ "$label" = "experimento" ] && continue
    printf "%-25s | %-10s | %-12s | %-12s | %-12s\n" \
        "$label" "$tf" "$pval" "$eval" "$qval"
done < $LOGS/tomtom_comparison.csv

echo ""
echo "  CSV completo: $LOGS/tomtom_comparison.csv"
echo "[$(date)] ETAPA 10 CONCLUÍDA"
