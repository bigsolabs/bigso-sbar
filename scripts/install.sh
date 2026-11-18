#!/bin/bash
set -euo pipefail

REPO="bigsolabs/bigso-sbar"
REF="${SCRIPTBAR_REF:-main}"
INSTALL_DIR="${SCRIPTBAR_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="ScriptBar.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ScriptBar requiere macOS." >&2
  exit 1
fi
if ! [[ "$REF" =~ ^[A-Za-z0-9._/-]+$ ]] || [[ "$REF" == *..* ]]; then
  echo "Referencia de Git no válida: $REF" >&2
  exit 1
fi
if ! command -v swift >/dev/null 2>&1; then
  echo "Falta Swift. Instala Xcode o las Command Line Tools de Xcode y vuelve a intentarlo." >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
  echo "Se requieren curl y tar." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/scriptbar-install.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
ARCHIVE="$WORK_DIR/source.tar.gz"
SOURCE_DIR="$WORK_DIR/source"
STAGED_APP="$WORK_DIR/$APP_NAME"
DESTINATION="$INSTALL_DIR/$APP_NAME"

mkdir -p "$SOURCE_DIR"
echo "Descargando ScriptBar ($REF)..."
curl --fail --location --silent --show-error \
  "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" \
  --output "$ARCHIVE"
tar -xzf "$ARCHIVE" --strip-components=1 -C "$SOURCE_DIR"

echo "Compilando ScriptBar..."
"$SOURCE_DIR/scripts/build-app.sh" >/dev/null
cp -R "$SOURCE_DIR/.build/ScriptBar.app" "$STAGED_APP"

mkdir -p "$INSTALL_DIR"
BACKUP=""
if [[ -e "$DESTINATION" ]]; then
  BACKUP="$WORK_DIR/previous-$APP_NAME"
  mv "$DESTINATION" "$BACKUP"
fi
if ! mv "$STAGED_APP" "$DESTINATION"; then
  if [[ -n "$BACKUP" && -e "$BACKUP" ]]; then
    mv "$BACKUP" "$DESTINATION"
  fi
  echo "No se pudo instalar ScriptBar en $DESTINATION" >&2
  exit 1
fi

echo "Instalado en: $DESTINATION"
open "$DESTINATION"
