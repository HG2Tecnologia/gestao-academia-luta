#!/bin/bash
# Compila o SenseiManagerCatracaAgent.exe e copia para wwwroot/agent/
# Rode este script no Mac antes de fazer deploy no Render.
# O .exe gerado ficará em: backend/src/AcademiaFight.API/wwwroot/agent/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_PROJECT="$SCRIPT_DIR/backend/src/AcademiaFight.CatracaAgent"
WWWROOT_AGENT="$SCRIPT_DIR/backend/src/AcademiaFight.API/wwwroot/agent"
PUBLISH_DIR="$AGENT_PROJECT/publish"

echo ">> Limpando publish anterior..."
rm -rf "$PUBLISH_DIR"

echo ">> Compilando agente para Windows x64..."
dotnet publish "$AGENT_PROJECT/AcademiaFight.CatracaAgent.csproj" \
  -c Release \
  -r win-x64 \
  --self-contained true \
  -p:PublishSingleFile=true \
  -o "$PUBLISH_DIR"

echo ">> Copiando .exe para wwwroot/agent/..."
mkdir -p "$WWWROOT_AGENT"
cp "$PUBLISH_DIR/SenseiManagerCatracaAgent.exe" "$WWWROOT_AGENT/"

echo ""
echo "Tamanho do executavel:"
ls -lh "$WWWROOT_AGENT/SenseiManagerCatracaAgent.exe"

echo ""
echo "Pronto! O arquivo wwwroot/agent/SenseiManagerCatracaAgent.exe esta pronto."
echo "Faca commit desse arquivo junto com o deploy para que o endpoint /api/catraca/agent/pacote funcione."
