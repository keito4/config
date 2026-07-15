#!/usr/bin/env bash
# Launch Claude Code against a local LM Studio server (Anthropic-compatible API).
# LM Studio 0.4.1+ serves POST /v1/messages natively, so no proxy is needed.
#
# IMPORTANT: use an MLX build of the model, not GGUF. Claude Code's tool schemas
# contain JSON-schema `pattern` regexes with `\w`, which llama.cpp's GBNF grammar
# parser rejects ("failed to parse grammar"). The MLX runtime handles these, so
# GGUF models fail on tool use while MLX models work end-to-end (verified 2026-07-15).
#
# The MLX runtime loads a vendored CPython from
# ~/.lmstudio/extensions/backends/vendor/_amphibian/cpython3.11-mac-arm64@*. If that
# directory goes missing, every MLX model fails to load with
# "Library not loaded: @rpath/libpython3.11.dylib"; repair it from the LM Studio app's
# Runtime tab (`lms runtime update`/`get` report it as already installed and do not fix it).

set -euo pipefail

BASE_URL="${LMSTUDIO_BASE_URL:-http://localhost:1234}"
MODEL="${LMSTUDIO_MODEL:-qwen/qwen3-coder-next}" # MLX build; override for another MLX model
AUTH_TOKEN="${LMSTUDIO_AUTH_TOKEN:-lmstudio}"
CONTEXT_LENGTH="${LMSTUDIO_CONTEXT_LENGTH:-262144}"

usage() {
  cat <<'EOF'
Usage: claude-lmstudio [claude-args...]

Runs `claude` with ANTHROPIC_BASE_URL pointed at a local LM Studio server.
Any extra arguments are passed through to the claude CLI.

Environment overrides:
  LMSTUDIO_BASE_URL        LM Studio endpoint (default: http://localhost:1234)
  LMSTUDIO_MODEL           Model id to request (default: qwen/qwen3-coder-next, MLX build)
  LMSTUDIO_AUTH_TOKEN      Auth token if LM Studio requires one (default: lmstudio)
  LMSTUDIO_CONTEXT_LENGTH  Context window to load the model with (default: 262144)

Use an MLX build of the model. GGUF models fail on Claude Code tool use because
llama.cpp's grammar parser rejects the `\w` regex in tool JSON schemas.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for cli in claude lms; do
  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "claude-lmstudio: '${cli}' CLI not found in PATH" >&2
    exit 1
  fi
done

# Fail fast if the local server is unreachable, with a clear hint.
if ! curl -fsS -m 3 "${BASE_URL}/v1/models" >/dev/null 2>&1; then
  echo "claude-lmstudio: cannot reach LM Studio at ${BASE_URL}." >&2
  echo "  Start it with: lms server start --port 1234 (or launch the LM Studio app)." >&2
  exit 1
fi

# LM Studio's JIT loader picks an 8k context, which cannot even hold Claude Code's
# system prompt ("number of tokens to keep from the initial prompt is greater than
# the context length"). Report the resident copies of $MODEL, splitting them by
# whether their window is big enough: `usable` on the first line, then one
# too-small identifier per line.
resident_copies() {
  lms ps --json 2>/dev/null |
    MODEL="$MODEL" CONTEXT_LENGTH="$CONTEXT_LENGTH" node -e '
      let raw = "";
      process.stdin.on("data", (c) => (raw += c));
      process.stdin.on("end", () => {
        const want = Number(process.env.CONTEXT_LENGTH);
        const copies = JSON.parse(raw || "[]").filter((m) => m.modelKey === process.env.MODEL);
        console.log(copies.filter((m) => m.contextLength >= want).length);
        for (const m of copies.filter((m) => m.contextLength < want)) console.log(m.identifier);
      });
    '
}

# Loading a second copy alongside a small one is not enough: LM Studio routes by model
# key and keeps serving the small copy, so drop those before loading a usable one.
usable_count=""
while read -r line; do
  if [[ -z "$usable_count" ]]; then
    usable_count="$line"
  else
    echo "claude-lmstudio: unloading ${line} (context below ${CONTEXT_LENGTH})..." >&2
    lms unload "$line" >&2
  fi
done < <(resident_copies)

if [[ "${usable_count:-0}" -eq 0 ]]; then
  echo "claude-lmstudio: loading ${MODEL} with a ${CONTEXT_LENGTH}-token context..." >&2
  lms load "$MODEL" --context-length "$CONTEXT_LENGTH" -y >&2
fi

export ANTHROPIC_BASE_URL="$BASE_URL"
export ANTHROPIC_AUTH_TOKEN="$AUTH_TOKEN"
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

exec claude --model "$MODEL" "$@"
