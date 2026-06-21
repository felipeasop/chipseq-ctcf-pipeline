#!/bin/bash
#
# run_pipeline.sh — Script mestre: executa o pipeline completo em sequência
#
# USO:
#   bash run_pipeline.sh          → roda tudo
#   bash run_pipeline.sh 6 8      → roda apenas etapas 6 a 8
#
# PRÉ-REQUISITOS:
#   1. FASTQs baixados em data/raw/
#   2. Genoma baixado e descomprimido em genome/
#   3. 00_config.sh ajustado com os arquivos ChIP e controle corretos
#   4. conda activate chipseq
#
set -euo pipefail

SCRIPTS=~/Projetos/chipseq-analysis/scripts
LOG=~/Projetos/chipseq-analysis/logs/pipeline_master.log
mkdir -p ~/Projetos/chipseq-analysis/logs

# Etapas disponíveis
START=${1:-2}   # Etapa inicial (padrão: 2)
END=${2:-10}    # Etapa final   (padrão: 10)

run_step() {
    local N=$1

    local PAD_N=$(printf "%02d" $N)

    # Expansão de glob precisa ocorrer em contexto que permita múltiplos
    # resultados — usar array em vez de atribuição direta a string.
    local MATCHES=($SCRIPTS/${PAD_N}_*.sh)
    local SCRIPT=${MATCHES[0]}

    if [ ! -f "$SCRIPT" ]; then
        echo "[AVISO] Nenhum script encontrado para etapa $PAD_N (padrão ${PAD_N}_*.sh) — pulando."
        return
    fi

    local LABEL=$(basename "$SCRIPT" .sh)

    if [ $N -ge $START ] && [ $N -le $END ]; then
        echo ""
        echo "########################################"
        echo "# Iniciando: $LABEL"
        echo "# $(date)"
        echo "########################################"
        bash "$SCRIPT"
        echo "# Concluído: $LABEL — $(date)"
    fi
}

echo "PIPELINE ChIP-seq CTCF — ENCSR921ERP"
echo "Início: $(date)"
echo "Etapas: $START a $END"

# Nota: Etapa 3 (indexação do genoma) deve ser rodada separadamente
# antes do pipeline principal, pois demora ~2 horas

run_step 2   # QC + Trim Galore
run_step 4   # Alinhamento Bowtie2
run_step 5   # Picard MarkDuplicates
run_step 6   # MACS3 peak calling
run_step 7   # Extração de sequências
run_step 8   # Descoberta de motivos
run_step 9   # Estratificação de picos
run_step 10  # TOMTOM × JASPAR

echo ""
echo "PIPELINE CONCLUÍDO — $(date)"
echo "Logs em: ~/Projetos/chipseq-analysis/logs/"
