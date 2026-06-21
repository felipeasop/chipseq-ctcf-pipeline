#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/00_config.sh"

mkdir -p "$DATA_RAW" "$DATA_RAW/ctrl"

echo "[$(date)] Iniciando download dos FASTQs"

download_one() {
    local outpath="$1"
    local acc
    acc=$(basename "$outpath" .fastq.gz)

    if [ -s "$outpath" ]; then
        echo "Já existe: $outpath"
        return 0
    fi

    wget -c --show-progress \
        -O "$outpath" \
        "https://www.encodeproject.org/files/${acc}/@@download/${acc}.fastq.gz"
}

echo "[$(date)] Baixando arquivos ChIP (${#CHIP_FILES[@]})..."
for f in "${CHIP_FILES[@]}"; do
    download_one "$f"
done

echo "[$(date)] Baixando arquivos de controle (${#CTRL_FILES[@]})..."
for f in "${CTRL_FILES[@]}"; do
    download_one "$f"
done

echo "[$(date)] Download concluído"
