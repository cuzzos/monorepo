# Prompts Directory

This directory stores reusable prompt templates designed to assist AI systems with code-related tasks.

## Structure

```
prompts/
  review-code/           # Code review prompts
    for-basic.md         # General code review
    for-security.md      # Security-focused analysis
    for-performance.md   # Performance-focused analysis
    for-quick-check.md   # Pre-commit quick check
  summarize-code/        # Summarization prompts
    for-pr-description.md # Generate PR descriptions
```

## Naming Convention

- **Folder**: `{verb}-{noun}` — the action being performed
- **File**: `for-{focus}.md` — the specific focus or use case

## Adding New Prompts

1. Choose the appropriate folder (or create a new `{verb}-{noun}/` folder)
2. Create `for-{focus}.md` with your prompt
3. Follow the existing format:
   - Clear role definition at the top
   - Numbered sections for expected output
   - `## ✅ DO` section with best practices
   - `## ❌ DON'T` section with anti-patterns

## Usage

Prompts are referenced by path: `{folder}/{file}` (without `.md`)

```bash
# Via justfile (recommended)
just review                    # All review-code/* prompts
just review for-security       # Specific focus
just summarize                 # All summarize-code/* prompts

# Via Dagger directly
dagger call execute-prompts --prompts=review-code/for-basic,review-code/for-security
```
