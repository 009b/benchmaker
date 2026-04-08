#!/usr/bin/env bash
# run_benchmarks.sh — launch benchmaker.py for every model.
# Edit MODELS below to add/remove models.
#
# Usage: ./run_benchmarks.sh [--mode small|big] [--prompts <file>]
#   --mode small  (default) send each line as a separate prompt
#   --mode big              send the entire file as one prompt
#   --prompts <file>        override the prompt file from config.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="${PYTHON:-python3}"
BENCHMARKER="${SCRIPT_DIR}/benchmaker.py"
MODE="small"
PROMPTS=""

# ── parse arguments ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --prompts)
      PROMPTS="$2"
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument '$1'" >&2
      echo "Usage: $0 [--mode small|big] [--prompts <file>]" >&2
      exit 1
      ;;
  esac
done

if [[ "$MODE" != "small" && "$MODE" != "big" ]]; then
  echo "ERROR: --mode must be 'small' or 'big', got '$MODE'" >&2
  exit 1
fi

# ── models to benchmark ────────────────────────────────────────────────────────
MODELS=(
  "gemma4:31b-cloud"
  "qwen3.5:9b"
  "nemotron-3-nano:30b"
  "lfm2:24b"
  "gemma4:26b"
  "gemma4:e4b"
  "minimax-m2.5:cloud"
  "qwen3:8b"
  "gpt-oss:20b"
  "qwen3-coder-next:latest"
)
# ──────────────────────────────────────────────────────────────────────────────

if [[ ! -f "$BENCHMARKER" ]]; then
  echo "ERROR: benchmaker.py not found at $BENCHMARKER" >&2
  exit 1
fi

if [[ -n "$PROMPTS" && ! -f "$PROMPTS" ]]; then
  echo "ERROR: prompts file not found at $PROMPTS" >&2
  exit 1
fi

echo "========================================"
echo " Ollama LLM Benchmark"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo " Mode   : $MODE"
echo " Models : ${MODELS[*]}"
echo " Prompts: ${PROMPTS:-<from config.json>}"
echo "========================================"
echo ""

FAILED=()

for model in "${MODELS[@]}"; do
  echo "----------------------------------------"
  echo " Starting: $model"
  echo "----------------------------------------"
  CMD=("$PYTHON" "$BENCHMARKER" "$model" "$MODE")
  [[ -n "$PROMPTS" ]] && CMD+=("$PROMPTS")
  if "${CMD[@]}"; then
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
