# benchmaker2

A lightweight benchmarking tool for locally-hosted LLMs via [Ollama](https://ollama.com). Measures throughput (tokens/sec) and token counts across models and prompt sets, writing results to CSV files for easy analysis.

## Usage

### Benchmark a single model

```bash
cd benchmaker
python benchmaker.py <model_name>
```

Example:

```bash
python benchmaker.py mistral
python benchmaker.py gemma3
python benchmaker.py gemma4:31b-cloud
```

### Benchmark all configured models

```bash
cd benchmaker
bash run_benchmarks.sh
```

Edit the `MODELS` array in `run_benchmarks.sh` to control which models are tested:

```bash
MODELS=(
  "gemma4:31b-cloud"
  "mistral"
  "gemma3"
)
```

## Output

Results are appended to two CSV files:

| File | Contents |
|------|----------|
| `data/data.out` | Raw per-prompt results: timestamp, model, prompt index, input/output/total tokens, tok/s, duration |
| `data/result.out` | Aggregated summary: one row per model per run date, with average tok/s and totals |

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
| `benchmark.prompts_file` | `prompts/prompts.txt` | Folder with prompt files |
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
