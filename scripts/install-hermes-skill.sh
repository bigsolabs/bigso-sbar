#!/bin/bash
set -euo pipefail

REF="${SCRIPTBAR_REF:-main}"
if ! [[ "$REF" =~ ^[A-Za-z0-9._/-]+$ ]] || [[ "$REF" == *..* ]]; then
  echo "Referencia de Git no válida: $REF" >&2
  exit 1
fi
if ! command -v hermes >/dev/null 2>&1; then
  echo "No encuentro Hermes Agent. Instala Hermes y vuelve a intentarlo." >&2
  exit 1
fi

SKILL_URL="https://raw.githubusercontent.com/bigsolabs/bigso-sbar/$REF/skills/scriptbar/SKILL.md"
echo "Instalando la skill ScriptBar en Hermes desde $REF..."
hermes skills install "$SKILL_URL" --name scriptbar --yes
