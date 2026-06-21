#!/bin/bash
set -euo pipefail

OUTDIR=~/Projetos/chipseq-analysis/data/raw
mkdir -p "$OUTDIR"
cd "$OUTDIR"

echo "[$(date)] Iniciando download dos FASTQs — ENCSR921ERP"

# Arquivos de ChIP (CTCF)
wget -c --show-progress https://www.encodeproject.org/files/ENCFF161RYH/@@download/ENCFF161RYH.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF428TVA/@@download/ENCFF428TVA.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF486GBD/@@download/ENCFF486GBD.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF614GZH/@@download/ENCFF614GZH.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF700JAD/@@download/ENCFF700JAD.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF762MPL/@@download/ENCFF762MPL.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF776CXY/@@download/ENCFF776CXY.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF912JBU/@@download/ENCFF912JBU.fastq.gz

# Arquivos de controle (input)
wget -c --show-progress https://www.encodeproject.org/files/ENCFF005HYS/@@download/ENCFF005HYS.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF054WBD/@@download/ENCFF054WBD.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF183MEQ/@@download/ENCFF183MEQ.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF293ZBN/@@download/ENCFF293ZBN.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF307BKD/@@download/ENCFF307BKD.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF487GTT/@@download/ENCFF487GTT.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF622UBF/@@download/ENCFF622UBF.fastq.gz
wget -c --show-progress https://www.encodeproject.org/files/ENCFF933AKF/@@download/ENCFF933AKF.fastq.gz

echo "[$(date)] Download concluído"
echo "Arquivos baixados:"
ls -lh "$OUTDIR"/*.fastq.gz
