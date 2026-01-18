# LLM Prompts for Code Review

This folder contains prompt templates for different review modes.

## Available Prompts

| File | Use Case |
|------|----------|
| `review-default.md` | General PR review (bugs, style, clarity) |
| `review-security.md` | Security-focused audit |
| `review-performance.md` | Performance analysis |
| `review-staged.md` | Quick pre-commit sanity check |

## Usage

Prompts are loaded by the Dagger module based on the `--mode` flag:

```bash
# Default review
dagger -m ./devtools/code call review-diff --source=. --base=main --head=HEAD

# Security audit
dagger -m ./devtools/code call review-diff --source=. --base=main --head=HEAD --mode=security

# Performance review  
dagger -m ./devtools/code call review-diff --source=. --base=main --head=HEAD --mode=performance
```

## Creating Custom Prompts

1. Create a new `.md` file in this folder
2. Use clear instructions with numbered sections
3. Include a DO/DON'T section for guardrails
4. Include examples of desired output format

Prompts are loaded from this folder at runtime based on the `--mode` flag.

## Tips for Good Prompts

- **Be specific**: "Find SQL injection" > "Find security issues"
- **Prioritize**: Tell the model what matters most
- **Format output**: Request structured output (numbered lists, severity ratings)
- **Set scope**: "Only comment on significant issues" reduces noise
