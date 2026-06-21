#!/bin/bash
#
# 09_stratify.sh — Estratificação de picos por confiança
# Ferramentas: BEDTools 2.31.1, STREME 5.5.9
#
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/00_config.sh"

mkdir -p "$TABLES"

LOG=$LOGS/09_stratify.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 9 — Estratificação (top10/25/50, nmotifs 1)"

PEAKS=$RESULTS/peaks/peaks_sorted.narrowPeak
BG=$RESULTS/peaks/background_markov.txt
MOTIFS=$RESULTS/motifs
TABLE=$TABLES/stratification_results.csv

TOTAL=$(wc -l < "$PEAKS")
echo "  Total de picos: $TOTAL"

echo "percentil,n_peaks,n_seqs,evalue" > "$TABLE"

extract_streme_evalue() {
    local file="$1"
    local eval

    eval=$(grep -m1 "letter-probability matrix" "$file" \
        | sed -E 's/.*E= *([^ ]+).*/\1/' || true)

    if [ -z "${eval:-}" ]; then
        echo "NA"
    else
        echo "$eval"
    fi
}

run_streme() {
    local PCT="$1"
    local N="$2"
    local LABEL="top${PCT}"

    echo "[$(date)] $LABEL ($N picos)..."

    head -n "$N" "$PEAKS" > "$RESULTS/peaks/${LABEL}.narrowPeak"

    awk '{print $1"\t"$2+$10"\t"$2+$10+1"\t"$4"\t"$5}' \
        "$RESULTS/peaks/${LABEL}.narrowPeak" \
        > "$RESULTS/peaks/${LABEL}_summits.bed"

    bedtools slop -i "$RESULTS/peaks/${LABEL}_summits.bed" \
        -g "$GENOME_SIZES" -b "$PEAK_EXTENSION" \
        > "$RESULTS/peaks/${LABEL}_extended.bed"

    bedtools getfasta -fi "$GENOME_FA" \
        -bed "$RESULTS/peaks/${LABEL}_extended.bed" \
        -fo "$RESULTS/peaks/${LABEL}_seq.fa"

    local N_SEQS
    N_SEQS=$(grep -c '^>' "$RESULTS/peaks/${LABEL}_seq.fa")
    echo "  Sequências: $N_SEQS"

    streme --p "$RESULTS/peaks/${LABEL}_seq.fa" --dna \
        --minw 15 --maxw 21 --bfile "$BG" \
        --oc "$MOTIFS/streme_${LABEL}" \
        --nmotifs 1 --thresh 0.05

    local EVAL
    EVAL=$(extract_streme_evalue "$MOTIFS/streme_${LABEL}/streme.txt")
    echo "  E-value: $EVAL"

    echo "$PCT,$N,$N_SEQS,$EVAL" >> "$TABLE"
}

N10=$((TOTAL * 10 / 100))
N25=$((TOTAL * 25 / 100))
N50=$((TOTAL * 50 / 100))

run_streme 10 "$N10"
run_streme 25 "$N25"
run_streme 50 "$N50"

# top100 = resultado já existente do script 08
if [ -f "$MOTIFS/streme/streme.txt" ]; then
    EVAL100=$(extract_streme_evalue "$MOTIFS/streme/streme.txt")
    NSEQS100=$(grep -c '^>' "$RESULTS/peaks/sequences.fa" 2>/dev/null || echo "NA")
    echo "100,$TOTAL,$NSEQS100,$EVAL100" >> "$TABLE"
fi

echo ""
echo "=== RESULTADO ==="
cat "$TABLE"
echo "[$(date)] ETAPA 9 CONCLUÍDA"
