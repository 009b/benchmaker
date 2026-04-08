#!/usr/bin/env bash
# run_benchmarks.sh — launch benchmaker.py for every (model × prompt-set) pair.
# Edit MODELS below to add/remove models.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="${PYTHON:-python3}"
BENCHMARKER="${SCRIPT_DIR}/benchmaker.py"
PROMPTS="${SCRIPT_DIR}/prompts/prompts.txt"

# ── models to benchmark ────────────────────────────────────────────────────────
MODELS=(
  "gemma4:31b-cloud"
  "mistral"
  "gemma3"
)
# ──────────────────────────────────────────────────────────────────────────────

if [[ ! -f "$BENCHMARKER" ]]; then
  echo "ERROR: benchmaker.py not found at $BENCHMARKER" >&2
  exit 1
fi

if [[ ! -f "$PROMPTS" ]]; then
  echo "ERROR: prompts.txt not found at $PROMPTS" >&2
  exit 1
fi

echo "========================================"
echo " Ollama LLM Benchmark"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo " Models : ${MODELS[*]}"
echo " Prompts: $PROMPTS"
echo "========================================"
echo ""

FAILED=()

for model in "${MODELS[@]}"; do
  echo "----------------------------------------"
  echo " Starting: $model"
  echo "----------------------------------------"
  if "$PYTHON" "$BENCHMARKER" "$model"; then
    echo " [OK] $model"
  else
    echo " [FAIL] $model — skipping"
    FAILED+=("$model")
  fi
  echo ""
done

echo "========================================"
echo " Benchmark complete"
echo " Results : ${SCRIPT_DIR}/data/result.out"
echo " Raw data: ${SCRIPT_DIR}/data/data.out"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo " Failed  : ${FAILED[*]}"
fi
echo "========================================"
