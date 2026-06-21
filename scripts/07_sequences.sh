#!/bin/bash
#
# 07_sequences.sh — Extração de sequências dos picos
# Ferramenta: BEDTools 2.31.1
#
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/00_config.sh"

LOG=$LOGS/07_sequences.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 7 — Extração de sequências"

SUMMITS=$RESULTS/peaks/ctcf_summits.bed
PEAKS=$RESULTS/peaks/ctcf_peaks.narrowPeak

# 7.1 Estender 100bp ao redor de cada summit
# Justificativa: o motivo do CTCF tem ~19bp mas o summit pode não estar
# exatamente centralizado. 200bp totais capturam o contexto do sítio.
echo "[$(date)] Estendendo summits em ${PEAK_EXTENSION}bp..."
bedtools slop \
    -i $SUMMITS \
    -g $GENOME_SIZES \
    -b $PEAK_EXTENSION \
    > $RESULTS/peaks/summits_extended.bed

echo "  Regiões estendidas: $(wc -l < $RESULTS/peaks/summits_extended.bed)"

# 7.2 Extrair sequências FASTA
echo "[$(date)] Extraindo sequências FASTA..."
bedtools getfasta \
    -fi $GENOME_FA \
    -bed $RESULTS/peaks/summits_extended.bed \
    -fo $RESULTS/peaks/sequences_all.fa

echo "  Sequências extraídas: $(grep -c '>' $RESULTS/peaks/sequences_all.fa)"

# 7.3 Verificar qualidade das sequências (sem Ns excessivos)
# Sequências com >10% de Ns são problemáticas para o MEME
echo "[$(date)] Filtrando sequências com excesso de Ns..."
python3 - << 'PYEOF'
import os, re

input_fa  = os.path.expanduser("~/Projetos/chipseq-analysis/results/peaks/sequences_all.fa")
output_fa = os.path.expanduser("~/Projetos/chipseq-analysis/results/peaks/sequences.fa")

kept, removed = 0, 0
with open(input_fa) as fin, open(output_fa, "w") as fout:
    header = None
    seq = []
    for line in fin:
        line = line.rstrip()
        if line.startswith(">"):
            if header:
                s = "".join(seq)
                n_pct = s.upper().count("N") / len(s) if s else 1
                if n_pct <= 0.1:
                    fout.write(header + "\n" + s + "\n")
                    kept += 1
                else:
                    removed += 1
            header = line
            seq = []
        else:
            seq.append(line)
    if header:
        s = "".join(seq)
        n_pct = s.upper().count("N") / len(s) if s else 1
        if n_pct <= 0.1:
            fout.write(header + "\n" + s + "\n")
            kept += 1
        else:
            removed += 1

print(f"  Sequências mantidas: {kept}")
print(f"  Sequências removidas (>10% Ns): {removed}")
print(f"  Arquivo final: {output_fa}")
PYEOF

echo ""
echo "[$(date)] ETAPA 7 CONCLUÍDA"
echo "  Sequências para motif discovery: $RESULTS/peaks/sequences.fa"
