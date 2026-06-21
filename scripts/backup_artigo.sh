#!/bin/bash
#
# backup_artigo.sh — Coleta os arquivos essenciais para o artigo
#
# Copia apenas resultados pequenos e textuais (logs, CSVs, tabelas,
# motifs/PWMs, narrowPeak, métricas) para uma pasta separada, sem
# duplicar os arquivos grandes (BAMs, FASTQs, genoma, SAMs).
#
# Pode ser rodado quantas vezes quiser — é incremental e seguro,
# sempre sobrescreve com a versão mais recente.
#
# USO:
#   bash backup_artigo.sh
#
set -euo pipefail

BASE_DIR=~/Projetos/chipseq-analysis
BACKUP_DIR=$BASE_DIR/artigo_dados
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "[$(date)] Iniciando backup dos dados essenciais para o artigo..."

mkdir -p "$BACKUP_DIR"/{logs,csv,peaks,motifs,tomtom,metrics}

# 1. Logs completos de cada etapa (texto, pequenos)
echo "[1/6] Copiando logs..."
cp -v $BASE_DIR/logs/*.log "$BACKUP_DIR/logs/" 2>/dev/null || echo "  (alguns logs ainda não existem — ok se etapas não rodaram)"

# 2. CSVs de resultados — viram tabelas do artigo direto
echo "[2/6] Copiando CSVs de resultados..."
cp -v $BASE_DIR/logs/stratification_results.csv "$BACKUP_DIR/csv/" 2>/dev/null || echo "  (stratification_results.csv ainda não existe)"
cp -v $BASE_DIR/logs/tomtom_comparison.csv "$BACKUP_DIR/csv/" 2>/dev/null || echo "  (tomtom_comparison.csv ainda não existe)"

# 3. Picos identificados (narrowPeak, summits — são pequenos, texto)
echo "[3/6] Copiando arquivos de picos..."
cp -v $BASE_DIR/results/peaks/*.narrowPeak "$BACKUP_DIR/peaks/" 2>/dev/null || true
cp -v $BASE_DIR/results/peaks/*summits*.bed "$BACKUP_DIR/peaks/" 2>/dev/null || true
cp -v $BASE_DIR/results/peaks/background_markov.txt "$BACKUP_DIR/peaks/" 2>/dev/null || true

# 4. Motifs — PWMs e relatórios do MEME/STREME (sem os arquivos HTML grandes de imagem, se houver)
echo "[4/6] Copiando motifs (PWMs e relatórios texto)..."
for dir in meme_oops meme_oops_markov meme_zoops streme streme_top10 streme_top25 streme_top50 streme_top100; do
    if [ -d "$BASE_DIR/results/motifs/$dir" ]; then
        mkdir -p "$BACKUP_DIR/motifs/$dir"
        cp -v $BASE_DIR/results/motifs/$dir/meme.txt "$BACKUP_DIR/motifs/$dir/" 2>/dev/null || true
        cp -v $BASE_DIR/results/motifs/$dir/streme.txt "$BACKUP_DIR/motifs/$dir/" 2>/dev/null || true
        cp -v $BASE_DIR/results/motifs/$dir/sites.tsv "$BACKUP_DIR/motifs/$dir/" 2>/dev/null || true
    fi
done

# 5. TOMTOM — resultados de comparação com JASPAR
echo "[5/6] Copiando resultados TOMTOM..."
if [ -d "$BASE_DIR/results/tomtom" ]; then
    find $BASE_DIR/results/tomtom -name "tomtom.tsv" -exec cp -v --parents {} "$BACKUP_DIR/tomtom/" \; 2>/dev/null || \
    for dir in $BASE_DIR/results/tomtom/*/; do
        name=$(basename "$dir")
        if [ -f "${dir}tomtom.tsv" ]; then
            mkdir -p "$BACKUP_DIR/tomtom/$name"
            cp -v "${dir}tomtom.tsv" "$BACKUP_DIR/tomtom/$name/"
        fi
    done
fi

# 6. Métricas de qualidade (Picard, flagstat, bowtie2 stats) — já estão em logs/ mas reforçando
echo "[6/6] Copiando métricas de QC e alinhamento..."
cp -v $BASE_DIR/logs/*_picard_metrics.txt "$BACKUP_DIR/metrics/" 2>/dev/null || true
cp -v $BASE_DIR/logs/*_flagstat.txt "$BACKUP_DIR/metrics/" 2>/dev/null || true
cp -v $BASE_DIR/logs/*_bowtie2_stats.txt "$BACKUP_DIR/metrics/" 2>/dev/null || true

# Resumo final
echo ""
echo "[$(date)] BACKUP CONCLUÍDO"
echo "  Local: $BACKUP_DIR"
echo ""
echo "  Tamanho total do backup:"
du -sh "$BACKUP_DIR"
echo ""
echo "  Estrutura:"
find "$BACKUP_DIR" -type f | sort

# Snapshot com timestamp (opcional — útil se quiser versionar cada rodada)
echo ""
echo "  Para versionar este snapshot específico, rode:"
echo "    cp -r $BACKUP_DIR $BASE_DIR/artigo_dados_snapshot_$TIMESTAMP"
