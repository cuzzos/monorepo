// AI-powered code analysis toolchain using local LLMs via Ollama.
//
// Prerequisites:
//   - Ollama running locally: ollama serve
//   - Model pulled: ollama pull gemma3:4b
//
// Usage from monorepo root:
//
//	# Review changes between branches
//	dagger -m ./devtools/code call review-diff --source=. --base=main --head=feature-branch
//
//	# Review staged changes
//	dagger -m ./devtools/code call review-staged --source=.
//
//	# Review a specific file
//	dagger -m ./devtools/code call review-file --source=. --file-path=src/main.rs
//
//	# Summarize changes for other developers
//	dagger -m ./devtools/code call summarize-diff --source=. --base=main --head=feature-branch
//
//	# Custom prompt for any diff
//	dagger -m ./devtools/code call analyze --source=. --base=main --head=HEAD --prompt="Find security issues"
//
//	# Use a specific review mode (loads prompt from prompts/ folder)
//	dagger -m ./devtools/code call review-diff --source=. --base=main --head=HEAD --mode=security

package main

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"

	"dagger/code/internal/dagger"
)

const (
	// Base image for reviewer containers
	alpineImage = "alpine:3.19"

	// Default model - gemma3:4b is a good balance of speed and quality
	defaultModel = "gemma3:4b"

	// Ollama host when running on the user's machine
	defaultOllamaHost = "host.docker.internal:11434"

	// Paths relative to module root
	configDir  = "config"
	promptsDir = "prompts"
)

type Code struct{}

// =============================================================================
// Container Helpers
// =============================================================================

// reviewerContainer creates a container with git and curl for interacting with Ollama.
func (m *Code) reviewerContainer(source *dagger.Directory, moduleDir *dagger.Directory) *dagger.Container {
	return dag.Container().
		From(alpineImage).
		WithExec([]string{"apk", "add", "--no-cache", "git", "curl", "jq"}).
		WithDirectory("/repo", source).
		WithDirectory("/module", moduleDir).
		WithWorkdir("/repo")
}

// =============================================================================
// Config Loading
// =============================================================================

// loadSkipPatterns reads skip patterns from config/skip-patterns.txt
func loadSkipPatterns(moduleDir *dagger.Directory, ctx context.Context) ([]string, error) {
	configFile := moduleDir.File(filepath.Join(configDir, "skip-patterns.txt"))
	content, err := configFile.Contents(ctx)
	if err != nil {
		// Return empty list if file doesn't exist
		return []string{}, nil
	}

	var patterns []string
	for _, line := range strings.Split(content, "\n") {
		line = strings.TrimSpace(line)
		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		patterns = append(patterns, line)
	}
	return patterns, nil
}

// loadPrompt reads a prompt from prompts/<mode>.md
func loadPrompt(moduleDir *dagger.Directory, mode string, ctx context.Context) (string, error) {
	promptFile := moduleDir.File(filepath.Join(promptsDir, fmt.Sprintf("review-%s.md", mode)))
	content, err := promptFile.Contents(ctx)
	if err != nil {
		return "", fmt.Errorf("prompt mode '%s' not found (looking for prompts/review-%s.md)", mode, mode)
	}
	return content, nil
}

// buildExcludeArgs creates git pathspec exclude arguments for skip patterns
func buildExcludeArgs(patterns []string) string {
	var excludes []string
	for _, pattern := range patterns {
		excludes = append(excludes, fmt.Sprintf("':!%s'", pattern))
	}
	return strings.Join(excludes, " ")
}

// =============================================================================
// Review Functions
// =============================================================================

// ReviewDiff reviews code changes between two git refs using a local LLM.
// Requires Ollama running on the host with the model already pulled.
func (m *Code) ReviewDiff(
	ctx context.Context,
	// Source directory (should be a git repository)
	source *dagger.Directory,
	// Base ref to compare from (e.g., "main", "origin/main")
	base string,
	// Head ref to compare to (e.g., "feature-branch", "HEAD")
	head string,
	// +optional
	// +default="default"
	// Review mode: default, security, performance, staged (loads from prompts/)
	mode string,
	// +optional
	// +default="gemma3:4b"
	model string,
	// +optional
	// +default="host.docker.internal:11434"
	ollamaHost string,
) (string, error) {
	moduleDir := dag.CurrentModule().Source()

	// Load prompt based on mode
	if mode == "" {
		mode = "default"
	}
	prompt, err := loadPrompt(moduleDir, mode, ctx)
	if err != nil {
		return "", err
	}

	return m.analyzeDiff(ctx, source, moduleDir, base, head, model, ollamaHost, prompt+"\n\nGit diff:\n")
}

// ReviewStaged reviews currently staged changes (git diff --cached).
func (m *Code) ReviewStaged(
	ctx context.Context,
	// Source directory (should be a git repository)
	source *dagger.Directory,
	// +optional
	// +default="gemma3:4b"
	model string,
	// +optional
	// +default="host.docker.internal:11434"
	ollamaHost string,
) (string, error) {
	moduleDir := dag.CurrentModule().Source()

	prompt, err := loadPrompt(moduleDir, "staged", ctx)
	if err != nil {
		return "", err
	}

	return m.analyzeDiff(ctx, source, moduleDir, "--cached", "", model, ollamaHost, prompt+"\n\nGit diff (staged):\n")
}

// ReviewFile reviews a single file for quality, bugs, and improvements.
func (m *Code) ReviewFile(
	ctx context.Context,
	// Source directory
	source *dagger.Directory,
	// Path to the file to review (relative to source root)
	filePath string,
	// +optional
	// +default="gemma3:4b"
	model string,
	// +optional
	// +default="host.docker.internal:11434"
	ollamaHost string,
) (string, error) {
	if model == "" {
		model = defaultModel
	}
	if ollamaHost == "" {
		ollamaHost = defaultOllamaHost
	}

	prompt := fmt.Sprintf(`You are reviewing the file: %s

Analyze this file and provide:
1. **Overview**: What does this file do?
2. **Issues**: Bugs, security concerns, or problems
3. **Improvements**: Suggestions for better code quality
4. **Rating**: Overall quality (1-10) with brief justification

File contents:
`, filePath)

	script := fmt.Sprintf(`
set -e
FILE_CONTENT=$(cat "%s" 2>/dev/null || echo "ERROR: File not found")
if [ "$FILE_CONTENT" = "ERROR: File not found" ]; then
    echo "Error: File '%s' not found"
    exit 1
fi

ESCAPED_CONTENT=$(echo "$FILE_CONTENT" | jq -Rs .)
ESCAPED_PROMPT=$(echo %s | jq -Rs .)

curl -s "http://%s/api/chat" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"%s\",
        \"messages\": [{
            \"role\": \"user\",
            \"content\": ${ESCAPED_PROMPT:1:-1}${ESCAPED_CONTENT:1:-1}
        }],
        \"stream\": false
    }" | jq -r '.message.content // .error // "Error: No response from model"'
`, filePath, filePath, prompt, ollamaHost, model)

	moduleDir := dag.CurrentModule().Source()
	return m.reviewerContainer(source, moduleDir).
		WithExec([]string{"sh", "-c", script}).
		Stdout(ctx)
}

// =============================================================================
// Summary Function (for explaining diffs to other developers)
// =============================================================================

// SummarizeDiff generates a human-friendly summary of code changes.
// Useful for helping other developers understand what changed and why.
func (m *Code) SummarizeDiff(
	ctx context.Context,
	// Source directory (should be a git repository)
	source *dagger.Directory,
	// Base ref to compare from (e.g., "main", "origin/main")
	base string,
	// Head ref to compare to (e.g., "feature-branch", "HEAD")
	head string,
	// +optional
	// +default="gemma3:4b"
	model string,
	// +optional
	// +default="host.docker.internal:11434"
	ollamaHost string,
) (string, error) {
	moduleDir := dag.CurrentModule().Source()

	prompt := `You are helping a developer understand code changes made by a teammate.

Write a clear, friendly summary that explains:

1. **What Changed** (2-3 sentences)
   - High-level description of the changes
   - Which parts of the codebase were affected

2. **Why It Matters**
   - What problem does this solve or feature does it add?
   - How does it affect the user or system?

3. **Key Details**
   - List the most important changes (max 5 bullet points)
   - Note any breaking changes or things to watch out for

4. **Files Changed**
   - Brief description of each file's changes (one line each)

Write as if explaining to a colleague who needs to review or work with this code.
Avoid jargon. Be specific but concise.

Git diff:
`
	return m.analyzeDiff(ctx, source, moduleDir, base, head, model, ollamaHost, prompt)
}

// =============================================================================
// Custom Analysis
// =============================================================================

// Analyze runs a custom analysis on a diff with a user-provided prompt.
func (m *Code) Analyze(
	ctx context.Context,
	// Source directory (should be a git repository)
	source *dagger.Directory,
	// Base ref to compare from
	base string,
	// Head ref to compare to
	head string,
	// Custom prompt describing what to analyze
	prompt string,
	// +optional
	// +default="gemma3:4b"
	model string,
	// +optional
	// +default="host.docker.internal:11434"
	ollamaHost string,
) (string, error) {
	moduleDir := dag.CurrentModule().Source()
	fullPrompt := prompt + "\n\nGit diff:\n"
	return m.analyzeDiff(ctx, source, moduleDir, base, head, model, ollamaHost, fullPrompt)
}

// =============================================================================
// Core Analysis Engine
// =============================================================================

// analyzeDiff is the core function that gets a diff and sends it to Ollama.
func (m *Code) analyzeDiff(
	ctx context.Context,
	source *dagger.Directory,
	moduleDir *dagger.Directory,
	base string,
	head string,
	model string,
	ollamaHost string,
	prompt string,
) (string, error) {
	if model == "" {
		model = defaultModel
	}
	if ollamaHost == "" {
		ollamaHost = defaultOllamaHost
	}

	// Load skip patterns from config
	skipPatterns, err := loadSkipPatterns(moduleDir, ctx)
	if err != nil {
		return "", fmt.Errorf("failed to load skip patterns: %w", err)
	}

	// Build the git diff command with file exclusions
	excludes := buildExcludeArgs(skipPatterns)
	var diffCmd string
	if base == "--cached" {
		diffCmd = fmt.Sprintf("git diff --cached -- . %s", excludes)
	} else if head == "" {
		diffCmd = fmt.Sprintf("git diff %s -- . %s", base, excludes)
	} else {
		diffCmd = fmt.Sprintf("git diff %s..%s -- . %s", base, head, excludes)
	}

	// Escape the prompt for JSON
	escapedPrompt := strings.ReplaceAll(prompt, `"`, `\"`)
	escapedPrompt = strings.ReplaceAll(escapedPrompt, "\n", `\n`)

	script := fmt.Sprintf(`
set -e

# Get the diff
DIFF=$(%s 2>/dev/null || echo "")
if [ -z "$DIFF" ]; then
    echo "No changes found between the specified refs."
    exit 0
fi

# Truncate if too large (keep first 50k chars to stay within context)
DIFF_LENGTH=${#DIFF}
if [ $DIFF_LENGTH -gt 50000 ]; then
    DIFF="${DIFF:0:50000}

... [truncated - diff too large, showing first 50k chars] ..."
    echo "Warning: Diff truncated from $DIFF_LENGTH to 50000 characters" >&2
fi

# Escape diff for JSON
ESCAPED_DIFF=$(echo "$DIFF" | jq -Rs .)

# Call Ollama
RESPONSE=$(curl -s "http://%s/api/chat" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"%s\",
        \"messages\": [{
            \"role\": \"user\",
            \"content\": \"%s\" 
        }, {
            \"role\": \"user\",
            \"content\": ${ESCAPED_DIFF}
        }],
        \"stream\": false
    }" 2>&1)

# Extract the response
echo "$RESPONSE" | jq -r '.message.content // .error // "Error: No response from Ollama. Is it running?"'
`, diffCmd, ollamaHost, model, escapedPrompt)

	return m.reviewerContainer(source, moduleDir).
		WithExec([]string{"sh", "-c", script}).
		Stdout(ctx)
}

// =============================================================================
// Utility Functions
// =============================================================================

// CheckOllama verifies that Ollama is running and the model is available.
func (m *Code) CheckOllama(
	ctx context.Context,
	// +optional
	// +default="gemma3:4b"
	model string,
	// +optional
	// +default="host.docker.internal:11434"
	ollamaHost string,
) (string, error) {
	if model == "" {
		model = defaultModel
	}
	if ollamaHost == "" {
		ollamaHost = defaultOllamaHost
	}

	script := fmt.Sprintf(`
set -e
echo "Checking Ollama at %s..."

# Check if Ollama is running
if ! curl -s "http://%s/api/tags" > /dev/null 2>&1; then
    echo "❌ Cannot connect to Ollama at %s"
    echo ""
    echo "To fix this, run: ollama serve"
    exit 1
fi
echo "✅ Ollama is running"

# Check if model is available
MODELS=$(curl -s "http://%s/api/tags" | jq -r '.models[].name')
if echo "$MODELS" | grep -q "^%s"; then
    echo "✅ Model '%s' is available"
else
    echo "❌ Model '%s' not found"
    echo ""
    echo "Available models:"
    echo "$MODELS" | head -10
    echo ""
    echo "To fix this, run: ollama pull %s"
    exit 1
fi

echo ""
echo "🎉 Ready to review code!"
`, ollamaHost, ollamaHost, ollamaHost, ollamaHost, model, model, model, model)

	return dag.Container().
		From(alpineImage).
		WithExec([]string{"apk", "add", "--no-cache", "curl", "jq"}).
		WithExec([]string{"sh", "-c", script}).
		Stdout(ctx)
}

// ListModes shows available review modes (prompts).
func (m *Code) ListModes(ctx context.Context) (string, error) {
	moduleDir := dag.CurrentModule().Source()
	promptsDirectory := moduleDir.Directory(promptsDir)

	entries, err := promptsDirectory.Entries(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to list prompts: %w", err)
	}

	var modes []string
	for _, entry := range entries {
		if strings.HasPrefix(entry, "review-") && strings.HasSuffix(entry, ".md") {
			mode := strings.TrimPrefix(entry, "review-")
			mode = strings.TrimSuffix(mode, ".md")
			modes = append(modes, mode)
		}
	}

	result := "Available review modes:\n"
	for _, mode := range modes {
		result += fmt.Sprintf("  - %s\n", mode)
	}
	result += "\nUsage: --mode=<mode>"
	return result, nil
}
