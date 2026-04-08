#!/usr/bin/env python3
"""
Benchmark an Ollama LLM model against all prompts in prompts.txt.
Usage: python benchmaker.py <model_name>

Outputs:
  data.out   — raw per-prompt results (CSV)
  result.out — aggregated summary per run (CSV)
"""

import json
import sys
import time
from datetime import datetime

import ollama

CONFIG_FILE = "config.json"


def load_config(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


_cfg         = load_config(CONFIG_FILE)
OLLAMA_HOST  = _cfg["ollama"]["host"]
PROMPTS_FILE = _cfg["benchmark"]["prompts_file"]
DATA_OUT     = _cfg["benchmark"]["data_out"]
RESULT_OUT   = _cfg["benchmark"]["result_out"]

DATA_HEADER   = "timestamp,model,prompt_id,input_tokens,output_tokens,processed_tokens,tokens_per_second,duration_s\n"
RESULT_HEADER = "date,model,avg_tokens_per_second,total_input_tokens,total_processed_tokens,total_output_tokens\n"


def load_prompts(path: str) -> list[str]:
    with open(path, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


def ensure_header(path: str, header: str) -> None:
    """Write header only if the file is new/empty."""
    try:
        with open(path, "r") as f:
            first = f.read(1)
        if first:
            return
    except FileNotFoundError:
        pass
    with open(path, "w", encoding="utf-8") as f:
        f.write(header)


def run_prompt(model: str, prompt: str) -> dict:
    """Run a single prompt and return metrics."""
    client = ollama.Client(host=OLLAMA_HOST)
    start = time.perf_counter()
    response = client.chat(
        model=model,
        messages=[{"role": "user", "content": prompt}],
    )
    elapsed = time.perf_counter() - start

    input_tokens     = response.prompt_eval_count or 0
    output_tokens    = response.eval_count or 0
    processed_tokens = input_tokens + output_tokens
    eval_duration_s  = (response.eval_duration or 0) / 1e9  # nanoseconds → seconds
    # prefer Ollama's own timing; fall back to wall-clock
    duration_s       = eval_duration_s if eval_duration_s > 0 else elapsed
    tps              = output_tokens / duration_s if duration_s > 0 else 0.0

    return {
        "input_tokens":     input_tokens,
        "output_tokens":    output_tokens,
        "processed_tokens": processed_tokens,
        "tokens_per_second": tps,
        "duration_s":       round(duration_s, 4),
    }


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python benchmaker.py <model_name>", file=sys.stderr)
        sys.exit(1)

    model   = sys.argv[1]
    prompts = load_prompts(PROMPTS_FILE)

    ensure_header(DATA_OUT,   DATA_HEADER)
    ensure_header(RESULT_OUT, RESULT_HEADER)

    now       = datetime.now()
    timestamp = now.strftime("%Y-%m-%d %H:%M:%S")
    date_str  = now.strftime("%Y-%m-%d")

    total_input     = 0
    total_output    = 0
    total_processed = 0
    tps_list        = []

    print(f"[benchmaker] model={model}  prompts={len(prompts)}")

    with open(DATA_OUT, "a", encoding="utf-8") as data_f:
        for idx, prompt in enumerate(prompts, start=1):
            print(f"  [{idx}/{len(prompts)}] {prompt[:60]}", end="", flush=True)
            try:
                m = run_prompt(model, prompt)
            except Exception as exc:
                print(f"  ERROR: {exc}")
                continue

            print(f"  -> {m['tokens_per_second']:.1f} tok/s")

            data_f.write(
                f"{timestamp},{model},{idx},"
                f"{m['input_tokens']},{m['output_tokens']},{m['processed_tokens']},"
                f"{m['tokens_per_second']:.2f},{m['duration_s']}\n"
            )

            total_input     += m["input_tokens"]
            total_output    += m["output_tokens"]
            total_processed += m["processed_tokens"]
            tps_list.append(m["tokens_per_second"])

    if not tps_list:
        print("[benchmaker] No successful runs — result not written.", file=sys.stderr)
        sys.exit(1)

    avg_tps = sum(tps_list) / len(tps_list)

    with open(RESULT_OUT, "a", encoding="utf-8") as res_f:
        res_f.write(
            f"{date_str},{model},{avg_tps:.2f},"
            f"{total_input},{total_processed},{total_output}\n"
        )

    print(
        f"[benchmaker] done — avg {avg_tps:.1f} tok/s | "
        f"in={total_input} proc={total_processed} out={total_output}"
    )


if __name__ == "__main__":
    main()
