#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
swift build -c release --package-path "$ROOT"

APP="$ROOT/.build/ScriptBar.app"
CONTENTS="$APP/Contents"
mkdir -p "$CONTENTS/MacOS"
cp "$ROOT/.build/release/ScriptBar" "$CONTENTS/MacOS/ScriptBar"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
echo "$APP"
