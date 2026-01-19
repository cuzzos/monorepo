# Code Analysis Devtool

AI-powered code analysis using local LLMs via Ollama and Dagger.

## Prerequisites

1. **Ollama** - Install and start:
   ```bash
   brew install ollama
   OLLAMA_HOST=0.0.0.0:11434 ollama serve &
   ollama pull gemma3:4b   # For code review (fast)
   ollama pull llama3:8b   # For summaries (better instruction following)
   ```

2. **Dagger** - Already configured in this monorepo

## Quick Start

### Via Justfile (Recommended)

```bash
# Run all review prompts in parallel
just review

# Run specific focus
just review for-security
just review for-performance

# Summarize changes for teammates
just summarize

# Review staged changes (pre-commit)
just quick-check
```

### Via Dagger Directly

```bash
# Step 1: Compute diff locally (fast)
git diff main..HEAD > /tmp/diff.txt

# Step 2: Run prompts
dagger -m ./devtools/code call execute-prompts \
    --diff-file=/tmp/diff.txt \
    --prompts=review-code/for-basic,review-code/for-security
```

## Available Functions

| Function | Description |
|----------|-------------|
| `execute-prompts` | Run one or more prompts against a diff file |
| `list-prompts` | Show all available prompts |
| `check-ollama` | Verify Ollama is running and model is available |

## Prompt Structure

```
prompts/
  review-code/           # Code review prompts
    for-basic.md         # General code review
    for-security.md      # Security-focused
    for-performance.md   # Performance-focused
    for-quick-check.md   # Pre-commit quick check
  summarize-code/        # Summarization prompts
    for-diff.md          # Explain changes to teammates
```

Prompts are specified as `{folder}/{file}` without the `.md` extension:
- `review-code/for-basic`
- `review-code/for-security`
- `summarize-code/for-diff`

## Design Decisions

### Why diff-file only?

We require a pre-computed diff file instead of computing it inside Dagger because:

1. **Speed**: Uploading the entire repo to Dagger adds ~12s overhead
2. **Simplicity**: Git computes diffs locally (fast) → Dagger runs LLM (containerized)
3. **Flexibility**: You can use any git diff options locally
4. **UX**: The justfile handles this transparently

### Why no containerized Ollama?

Running Ollama inside Docker means CPU-only inference (~60s per prompt vs ~3s with GPU).
For practical use, we rely on host Ollama with Metal GPU acceleration.

## Troubleshooting

Run the check command to diagnose issues:

```bash
just check-ollama
```

This will verify Ollama is running and the model is available, with fix instructions if not.
