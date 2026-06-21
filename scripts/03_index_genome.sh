#!/bin/bash

# 03_index_genome.sh — Indexação do genoma de referência GRCh38
# Ferramenta: Bowtie2 2.5.5
# script usa RAM intensivamente (~5gb)

set -euo pipefail
source ~/Projetos/chipseq-analysis/scripts/00_config.sh

LOG=$LOGS/03_index_genome.log
exec > >(tee -a "$LOG") 2>&1

echo "[$(date)] ETAPA 3 — Indexação do genoma"

mkdir -p $GENOME_DIR/index

# Verificar se o genoma foi baixado
if [ ! -f "$GENOME_FA" ]; then
    echo "ERRO: Arquivo do genoma não encontrado em $GENOME_FA"
    echo "Execute o download primeiro:"
    echo "  wget -c https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    echo "  gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
    exit 1
fi

# 3.1 Gerar índice FASTA (.fai) para uso posterior pelo BEDTools e SAMtools
echo "[$(date)] Gerando índice FASTA (.fai)..."
samtools faidx $GENOME_FA
echo "  Índice .fai criado."

# 3.2 Gerar arquivo de tamanho dos cromossomos (necessário para bedtools slop)
echo "[$(date)] Gerando arquivo de tamanhos de cromossomos..."
cut -f1,2 ${GENOME_FA}.fai > $GENOME_SIZES
echo "  Arquivo chrom.sizes criado: $GENOME_SIZES"

# 3.3 Construir índice Bowtie2
# Justificativa da troca Bowtie1 → Bowtie2:
#   - Reads SE76nt excedem o limite ideal do Bowtie1 (≤50bp)
#   - Bowtie2 suporta gaps (indels), recuperando reads descartados pelo Bowtie1
#   - Parâmetro --threads para paralelismo
echo "[$(date)] Construindo índice Bowtie2 (isso demora ~2h)..."
bowtie2-build \
    --threads $THREADS \
    $GENOME_FA \
    $GENOME_INDEX

echo ""
echo "[$(date)] ETAPA 3 CONCLUÍDA"
echo "  Índice Bowtie2: $GENOME_INDEX.*"
echo "  Tamanhos chr:   $GENOME_SIZES"
