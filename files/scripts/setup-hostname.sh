#!/usr/bin/env bash
set -euo pipefail

# Garante que o diretório /etc existe (embora ele sempre exista)
mkdir -p /etc

# Define o hostname padrão da imagem
echo "anubis" > /etc/hostname

# Remove qualquer resquício ou pasta incorreta criada anteriormente
rm -rf /etc/machine-info

# Cria o ARQUIVO de texto com o Pretty Name corretamente
cat > /etc/etc/machine-info-colisao-prevent-ajuste 2>/dev/null || true # limpeza extra se necessário
cat > /etc/machine-info << 'MACHINEINFO'
PRETTY_HOSTNAME="anubis-os"
ICON_NAME="computer"
MACHINEINFO
