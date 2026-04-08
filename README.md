# benchmaker2

A lightweight benchmarking tool for locally-hosted LLMs via [Ollama](https://ollama.com). Measures throughput (tokens/sec) and token counts across models and prompt sets, writing results to CSV files for easy analysis.

## Usage

### Benchmark a single model

```bash
cd benchmaker
python benchmaker.py <model_name> [small|big]
```

| Mode | Description |
|------|-------------|
| `small` (default) | Each line in the prompt file is sent as a separate prompt |
| `big` | The entire prompt file is sent as one single prompt |

Example:

```bash
python benchmaker.py gemma4:31b-cloud
python benchmaker.py gemma4:31b-cloud small
python benchmaker.py gemma4:31b-cloud big
```

### Benchmark all configured models

```bash
cd benchmaker
bash run_benchmarks.sh [--mode small|big]
```

Examples:

```bash
bash run_benchmarks.sh
bash run_benchmarks.sh --mode big
```

Edit the `MODELS` array in `run_benchmarks.sh` to control which models are tested:

```bash
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
```

## Warmup

Before running timed prompts, the tool sends a silent `"hi"` message to the model. This forces Ollama to load the model into memory so that load time does not skew benchmark results.

## Output

Results are appended to two CSV files:

| File | Contents |
|------|----------|
| `data/data.out` | Raw per-prompt results: timestamp, model, prompt index, input/output/total tokens, tok/s, duration |
| `data/result.out` | Aggregated summary: one row per model per run, with average tok/s and token totals |

## Configuration

Edit `benchmaker/config.json` to change the Ollama host or file paths:

```json
{
  "ollama": {
    "host": "http://127.0.0.1:11434"
  },
  "benchmark": {
    "prompts_file": "prompts/prompts.txt",
    "data_out":     "data/data.out",
    "result_out":   "data/result.out"
  }
}
```

| Key | Default | Description |
|-----|---------|-------------|
| `ollama.host` | `http://127.0.0.1:11434` | Ollama server URL |
| `benchmark.prompts_file` | `prompts/prompts.txt` | Prompt file to use |
| `benchmark.data_out` | `data/data.out` | Raw results output file |
| `benchmark.result_out` | `data/result.out` | Aggregated results output file |

The `PYTHON` environment variable overrides the Python executable used by `run_benchmarks.sh` (default: `python3`).

## Requirements

- Python 3.7+
- Ollama running locally
- `ollama` Python package

```bash
pip install ollama
```
