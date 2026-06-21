#!/bin/bash
#
# 08_motifs.sh — Descoberta de motivos (CONTRIBUIÇÃO NOVA DO ARTIGO)
# Ferramentas: MEME 5.5.9, STREME 5.5.9
#
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/00_config.sh"

LOG=$LOGS/08_motifs.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 8 — Descoberta de motivos"

SEQS=$RESULTS/peaks/sequences.fa
MOTIFS=$RESULTS/motifs

N_SEQS_MEME=1000
SEED=42

echo "[$(date)] Criando subconjunto de ${N_SEQS_MEME} sequências para MEME..."
python3 - << PYEOF
import random, os
random.seed($SEED)
fa = os.path.expanduser("$SEQS")
out = os.path.expanduser("${SEQS%.fa}_meme_subset.fa")
records = []
with open(fa) as f:
    header = None
    for line in f:
        line = line.rstrip()
        if line.startswith(">"):
            header = line
        else:
            records.append((header, line))
sample = random.sample(records, min($N_SEQS_MEME, len(records)))
with open(out, "w") as f:
    for h, s in sample:
        f.write(h + "\n" + s + "\n")
print(f"  Subconjunto criado: {out} ({len(sample)} sequências)")
PYEOF

SEQS_SUBSET=${SEQS%.fa}_meme_subset.fa

echo "[$(date)] Gerando modelo de background Markov (ordem 2)..."
fasta-get-markov \
    -m 2 \
    $SEQS \
    > $RESULTS/peaks/background_markov.txt

echo ""
echo "[$(date)] Exp A: MEME-OOPS + background uniforme (baseline)..."
meme $SEQS_SUBSET \
    -dna \
    -revcomp \
    -mod oops \
    -nmotifs 1 \
    -w $MOTIF_WIDTH \
    -oc $MOTIFS/meme_oops \
    -p $THREADS \
    -nostatus
echo "  Exp A concluído."

echo ""
echo "[$(date)] Exp B: MEME-OOPS + background Markov..."
meme $SEQS_SUBSET \
    -dna \
    -revcomp \
    -mod oops \
    -nmotifs 1 \
    -w $MOTIF_WIDTH \
    -bfile $RESULTS/peaks/background_markov.txt \
    -oc $MOTIFS/meme_oops_markov \
    -p $THREADS \
    -nostatus
echo "  Exp B concluído."

echo ""
echo "[$(date)] Exp C: MEME-ZOOPS + background Markov (correção metodológica)..."
meme $SEQS_SUBSET \
    -dna \
    -revcomp \
    -mod zoops \
    -nmotifs 1 \
    -w $MOTIF_WIDTH \
    -bfile $RESULTS/peaks/background_markov.txt \
    -oc $MOTIFS/meme_zoops \
    -p $THREADS \
    -nostatus
echo "  Exp C concluído."

echo ""
echo "[$(date)] Exp D: STREME + background Markov (abordagem moderna)..."
streme \
    --p $SEQS \
    --dna \
    --minw 15 \
    --maxw 21 \
    --bfile $RESULTS/peaks/background_markov.txt \
    --oc $MOTIFS/streme \
    --thresh 0.05
echo "  Exp D concluído."

echo ""
echo "[$(date)] RESUMO — E-values dos experimentos"

extract_evalue() {
    local DIR=$1
    local LABEL=$2
    if [ -f "$DIR/meme.txt" ]; then
        EVAL=$(grep "E-value" "$DIR/meme.txt" | head -1 | awk '{print $NF}' || echo "N/A")
        echo "  $LABEL: E-value = $EVAL"
    elif [ -f "$DIR/streme.txt" ]; then
        # Correção STREME: evita que o grep quebre o script e puxa o p-value com segurança
        EVAL=$(grep -E "p-value|E-value" "$DIR/streme.txt" 2>/dev/null | head -1 | awk '{print $NF}' || echo "Ver HTML")
        echo "  $LABEL: Resultado = $EVAL"
    fi
}

extract_evalue $MOTIFS/meme_oops       "Exp A (MEME-OOPS  + uniforme)"
extract_evalue $MOTIFS/meme_oops_markov "Exp B (MEME-OOPS  + Markov  )"
extract_evalue $MOTIFS/meme_zoops      "Exp C (MEME-ZOOPS + Markov  )"
extract_evalue $MOTIFS/streme          "Exp D (STREME     + Markov  )"

echo ""
echo "[$(date)] ETAPA 8 CONCLUÍDA"
