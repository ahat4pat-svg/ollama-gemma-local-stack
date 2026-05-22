# LiteLLM proxy — route local Ollama + cloud fallback

LiteLLM gives you **one OpenAI-compatible endpoint** that routes to your local Ollama box for cheap/private requests, and falls back to a cloud model (Claude, GPT, etc.) when the local one can't handle it (timeout, OOM, unknown error).

This is the missing piece between "I have Gemma running locally" and "my production scripts use it without rewriting anything."

## 1. Install

On the Mac orchestrator (or wherever your scripts run) :

```bash
pip install 'litellm[proxy]'
```

## 2. Config — `config.yaml`

Save this file next to where you'll run the proxy :

```yaml
model_list:
  # Primary worker — local Ollama via Tailscale
  - model_name: gemma-local
    litellm_params:
      model: ollama/gemma4:e4b
      api_base: http://patoupc:11434

  # Cloud fallback — Claude via Anthropic API
  - model_name: claude-fallback
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

router_settings:
  # Route to gemma-local first ; on timeout or 5xx, transparently retry on claude-fallback
  fallbacks:
    - gemma-local: [claude-fallback]
  timeout: 60         # seconds before we consider local "stuck"
  num_retries: 1

litellm_settings:
  drop_params: true   # silently drop OpenAI-only params Ollama doesn't understand
  set_verbose: false
```

Tweak `patoupc` to match your Windows hostname on the tailnet, and `gemma4:e4b` to whatever tag you actually pulled (check with `ollama list` on the HP).

## 3. Run the proxy

```bash
export ANTHROPIC_API_KEY=sk-ant-...
litellm --config config.yaml --port 4000
```

## 4. Use it like the OpenAI API

From any script / SDK / tool that speaks OpenAI :

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-local",
    "messages": [{"role": "user", "content": "Write a 2-line haiku about Quebec winter."}]
  }'
```

If `gemma-local` is down or times out, LiteLLM transparently retries on `claude-fallback`. Your script never sees the switch.

## Why this matters for the 100 % margin claim

- **Local Ollama** : $0 marginal cost per request.
- **Cloud fallback** : you only pay when local genuinely can't handle it — a few % of traffic, instead of 100 %.
- **Same API surface** : your existing OpenAI-shaped code keeps working unchanged.

## Adding more providers later

Add another entry under `model_list` :

```yaml
  # OpenRouter — access dozens of models with one key
  - model_name: openrouter-fallback
    litellm_params:
      model: openrouter/anthropic/claude-sonnet-4-6
      api_key: os.environ/OPENROUTER_API_KEY
```

Then extend the `fallbacks` chain : `gemma-local: [claude-fallback, openrouter-fallback]`.

## Troubleshooting

| Issue | Fix |
|---|---|
| `Connection refused` to `patoupc:11434` | Ollama not running, or Windows Firewall — see [`../windows/install-ollama-windows.md`](../windows/install-ollama-windows.md) §6 |
| Fallback never triggers despite local being slow | Local returned 200 with a junk response. Lower `timeout`, or add response-quality checks in your client |
| 401 on `claude-fallback` | `ANTHROPIC_API_KEY` not exported in the shell that runs `litellm` |
| Model name not recognized by Ollama | Match the tag from `ollama list` exactly (e.g. `gemma3:4b` if E4B wasn't available — see install script) |
