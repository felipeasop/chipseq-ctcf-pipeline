#!/bin/bash
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/09_stratify.log
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] ETAPA 9 — Estratificação (fast: top10/25/50, nmotifs 1)"

PEAKS=$RESULTS/peaks/peaks_sorted.narrowPeak
BG=$RESULTS/peaks/background_markov.txt
MOTIFS=$RESULTS/motifs
TOTAL=$(wc -l < $PEAKS)
echo "  Total de picos: $TOTAL"

echo "percentil,n_peaks,n_seqs,evalue" > $LOGS/stratification_results.csv

run_streme() {
    PCT=$1
    N=$2
    LABEL="top${PCT}"
    echo "[$(date)] $LABEL ($N picos)..."

    head -n $N $PEAKS > $RESULTS/peaks/${LABEL}.narrowPeak

    awk '{print $1"\t"$2+$10"\t"$2+$10+1"\t"$4"\t"$5}' \
        $RESULTS/peaks/${LABEL}.narrowPeak \
        > $RESULTS/peaks/${LABEL}_summits.bed

    bedtools slop -i $RESULTS/peaks/${LABEL}_summits.bed \
        -g $GENOME_SIZES -b $PEAK_EXTENSION \
        > $RESULTS/peaks/${LABEL}_extended.bed

    bedtools getfasta -fi $GENOME_FA \
        -bed $RESULTS/peaks/${LABEL}_extended.bed \
        -fo  $RESULTS/peaks/${LABEL}_seq.fa

    N_SEQS=$(grep -c '>' $RESULTS/peaks/${LABEL}_seq.fa)
    echo "  Sequencias: $N_SEQS"

    streme --p $RESULTS/peaks/${LABEL}_seq.fa --dna \
        --minw 15 --maxw 21 --bfile $BG \
        --oc $MOTIFS/streme_${LABEL} \
        --nmotifs 1 --thresh 0.05

    EVAL=$(grep "^MOTIF" $MOTIFS/streme_${LABEL}/streme.txt 2>/dev/null \
           | head -1 | awk '{print $6}')
    [ -z "$EVAL" ] && EVAL="NA"
    echo "  E-value: $EVAL"
    echo "$PCT,$N,$N_SEQS,$EVAL" >> $LOGS/stratification_results.csv
}

N10=$(echo "$TOTAL * 10 / 100" | bc)
N25=$(echo "$TOTAL * 25 / 100" | bc)
N50=$(echo "$TOTAL * 50 / 100" | bc)

run_streme 10 $N10
run_streme 25 $N25
run_streme 50 $N50

# top100 do resultado já existente do script 08
if [ -f "$MOTIFS/streme/streme.txt" ]; then
    EVAL100=$(grep "^MOTIF" $MOTIFS/streme/streme.txt | head -1 | awk '{print $6}')
    [ -z "$EVAL100" ] && EVAL100="NA"
    NSEQS100=$(grep -c '>' $RESULTS/peaks/sequences.fa 2>/dev/null || echo "NA")
    echo "100,$TOTAL,$NSEQS100,$EVAL100" >> $LOGS/stratification_results.csv
fi

echo ""
echo "=== RESULTADO ==="
cat $LOGS/stratification_results.csv
echo "[$(date)] ETAPA 9 CONCLUÍDA"
