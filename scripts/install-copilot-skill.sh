#!/usr/bin/env bash
set -euo pipefail

AGENT="github-copilot"
SCOPE="${SCRIPTBAR_SKILL_SCOPE:-user}"
PIN="${SCRIPTBAR_SKILL_PIN:-}"

if ! command -v gh >/dev/null 2>&1 || ! gh skill install --help >/dev/null 2>&1; then
  echo "Se requiere GitHub CLI 2.90.0 o posterior con 'gh skill install' (preview). Actualiza gh y vuelve a intentarlo." >&2
  exit 1
fi
if [[ "$SCOPE" != "user" && "$SCOPE" != "project" ]]; then
  echo "SCRIPTBAR_SKILL_SCOPE debe ser 'user' o 'project'." >&2
  exit 1
fi
if [[ "$SCOPE" == "project" ]] && ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "El scope 'project' requiere ejecutarse dentro de un repositorio Git." >&2
  exit 1
fi
if [[ -z "$PIN" ]]; then
  INSTALLED="$(gh skill list --scope "$SCOPE" --json skillName,agentHosts --jq "any(.[]; .skillName == \"scriptbar\" and (.agentHosts | index(\"$AGENT\") != null))")"
  if [[ "$INSTALLED" == "true" ]]; then
    echo "La skill ScriptBar ya está instalada para GitHub Copilot (scope: $SCOPE)."
    echo "Para actualizarla: gh skill update scriptbar"
    exit 0
  fi
fi

ARGS=(skill install bigsolabs/bigso-sbar skills/scriptbar --agent "$AGENT" --scope "$SCOPE")
if [[ -n "$PIN" ]]; then
  ARGS+=(--pin "$PIN")
fi

echo "Instalando la skill ScriptBar para GitHub Copilot (scope: $SCOPE)..."
gh "${ARGS[@]}"
