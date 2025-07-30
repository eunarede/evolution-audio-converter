#!/bin/bash

# Script de inicialização para garantir que FFmpeg está no PATH
echo "🔍 Verificando FFmpeg..."

# Tentar encontrar FFmpeg em diferentes locais
FFMPEG_PATHS=(
    "/usr/bin/ffmpeg"
    "/usr/local/bin/ffmpeg"
    "/nix/store/*/bin/ffmpeg"
    "$(which ffmpeg 2>/dev/null)"
)

FFMPEG_FOUND=""
for path in "${FFMPEG_PATHS[@]}"; do
    if [ -x "$path" ] 2>/dev/null; then
        FFMPEG_FOUND="$path"
        break
    fi
done

# Se encontrou FFmpeg, adiciona ao PATH
if [ -n "$FFMPEG_FOUND" ]; then
    export PATH="$(dirname "$FFMPEG_FOUND"):$PATH"
    echo "✅ FFmpeg encontrado em: $FFMPEG_FOUND"
    ffmpeg -version | head -1
else
    echo "❌ FFmpeg não encontrado!"
    echo "Tentando instalar FFmpeg..."
    
    # Tentativa de instalação em diferentes sistemas
    if command -v apk &> /dev/null; then
        apk add --no-cache ffmpeg
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y ffmpeg
    elif command -v yum &> /dev/null; then
        yum install -y ffmpeg
    fi
fi

# Verificação final
if command -v ffmpeg &> /dev/null; then
    echo "🚀 Iniciando aplicação..."
    exec ./out
else
    echo "💥 Erro: FFmpeg não está disponível. A aplicação pode não funcionar corretamente."
    exec ./out
fi
