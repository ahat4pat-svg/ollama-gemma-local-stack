# Gemma 4 on 16 GB — Local AI Server Kit troubleshooting log

Use this file to capture real install, test, and benchmark issues as the kit is tried on an actual Windows machine.

## Suggested log format

For each issue, capture:

- **Date**
- **Mode** (`Audit`, `Prepare`, `Install`, `Test`, or `Benchmark`)
- **Symptom**
- **Diagnosis**
- **Fix**
- **Model** (`gemma4:e4b`, `gemma4:26b`, or another explicit tag)
- **Notes**

## Known caution areas

- `gemma4:e4b` is the default target for 16 GB machines
- `gemma4:26b` should be treated as experimental on 16 GB machines
- if the API does not respond after env-var changes, quit and relaunch Ollama from the tray
- if models were stored on an external drive, check `OLLAMA_MODELS` before assuming the data is still on `C:`
- keep Tailscale installed if the machine is intended to stay reachable from other devices

## Issues encountered

_(empty for now — add real field notes here after testing on the target Windows machine)_
