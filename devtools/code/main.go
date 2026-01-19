// AI-powered code analysis toolchain using local LLMs via Ollama.
//
// Design Decisions:
//   - Diff-file only: Git computes diff locally (fast) → Dagger runs LLM (containerized)
//   - No self-contained Ollama: CPU-only containers too slow; rely on host/remote Ollama
//   - Parallel execution: ExecutePrompts runs multiple prompts concurrently
//
// Prerequisites:
//   - Ollama running: OLLAMA_HOST=0.0.0.0:11434 ollama serve
//   - Model pulled: ollama pull gemma3:4b
//
// Usage via justfile (recommended):
//
//	just review                     # Run all review prompts
//	just review for-security        # Run specific focus
//	just summarize                  # Run all summarize prompts
//
// Usage via Dagger directly:
//
//	# First, compute diff locally
//	git diff main..HEAD > /tmp/diff.txt
//
//	# Then run prompts
//	dagger -m ./devtools/code call execute-prompts \
//	    --diff-file=/tmp/diff.txt \
//	    --prompts=review-code/for-basic,review-code/for-security

package main

import (
	"bytes"
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"sync"
	"text/template"
	"time"

	"dagger/code/internal/dagger"
)

const (
	// Base image for containers
	alpineImage = "alpine:3.19"

	// Default model - gemma3:4b balances speed and instruction-following
	defaultModel = "gemma3:4b"

	// Ollama host when running on the user's machine
	defaultOllamaHost = "host.docker.internal:11434"

	// Paths relative to module root
	promptsDir = "prompts"
)

type Code struct{}

// =============================================================================
// Main Function
// =============================================================================

// ExecutePrompts runs one or more prompts against a diff file in parallel.
// This is the main entry point for all code analysis.
//
// Prompts are specified as paths relative to the prompts/ directory:
//   - "review-code/for-basic" → prompts/review-code/for-basic.md
//   - "review-code/for-security" → prompts/review-code/for-security.md
//   - "summarize-code/for-diff" → prompts/summarize-code/for-diff.md
func (m *Code) ExecutePrompts(
	ctx context.Context,
	// The diff file to analyze (compute with: git diff main..HEAD > diff.txt)
	diffFile *dagger.File,
	// Comma-separated list of prompts to run (e.g., "review-code/for-basic,review-code/for-security")
	prompts string,
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

	// Parse prompt list
	promptList := strings.Split(prompts, ",")
	for i := range promptList {
		promptList[i] = strings.TrimSpace(promptList[i])
	}

	if len(promptList) == 0 || (len(promptList) == 1 && promptList[0] == "") {
		return "", fmt.Errorf("no prompts specified")
	}

	// Read diff content
	diffContent, err := diffFile.Contents(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to read diff file: %w", err)
	}

	if strings.TrimSpace(diffContent) == "" {
		return "No changes in diff file.", nil
	}

	// Truncate if too large
	if len(diffContent) > 50000 {
		diffContent = diffContent[:50000] + "\n\n... [truncated - diff too large, showing first 50k chars] ..."
	}

	// Get module directory for loading prompts
	moduleDir := dag.CurrentModule().Source()

	// Run prompts in parallel
	type result struct {
		prompt   string
		output   string
		err      error
		duration time.Duration
	}

	results := make([]result, len(promptList))
	var wg sync.WaitGroup

	for i, prompt := range promptList {
		wg.Add(1)
		go func(idx int, promptPath string) {
			defer wg.Done()

			start := time.Now()
			output, err := m.executeOnePrompt(ctx, moduleDir, promptPath, diffContent, model, ollamaHost)
			duration := time.Since(start)

			results[idx] = result{prompt: promptPath, output: output, err: err, duration: duration}
		}(i, prompt)
	}

	wg.Wait()

	// Format prompt names for display
	formatPromptName := func(prompt string) string {
		name := strings.ReplaceAll(prompt, "/", " → ")
		name = strings.ReplaceAll(name, "for-", "")
		name = strings.Title(strings.ReplaceAll(name, "-", " "))
		return name
	}

	// Generate anchor ID for markdown links
	toAnchor := func(name string) string {
		anchor := strings.ToLower(name)
		anchor = strings.ReplaceAll(anchor, " → ", "-")
		anchor = strings.ReplaceAll(anchor, " ", "-")
		return anchor
	}

	// Format duration for display
	formatDuration := func(d time.Duration) string {
		if d < time.Second {
			return fmt.Sprintf("%dms", d.Milliseconds())
		}
		return fmt.Sprintf("%.1fs", d.Seconds())
	}

	// Combine results with table of contents
	var output strings.Builder

	// Table of contents (only if multiple prompts)
	if len(results) > 1 {
		output.WriteString("## Table of Contents\n\n")
		for _, r := range results {
			promptName := formatPromptName(r.prompt)
			anchor := toAnchor(promptName)
			output.WriteString(fmt.Sprintf("- [%s](#%s) (%s)\n", promptName, anchor, formatDuration(r.duration)))
		}
		output.WriteString("\n---\n\n")
	}

	// Content sections
	for i, r := range results {
		if i > 0 {
			output.WriteString("\n\n---\n\n")
		}

		promptName := formatPromptName(r.prompt)
		output.WriteString(fmt.Sprintf("# %s\n\n", promptName))
		output.WriteString(fmt.Sprintf("*Completed in %s*\n\n", formatDuration(r.duration)))

		if r.err != nil {
			output.WriteString(fmt.Sprintf("Error: %v\n", r.err))
		} else {
			output.WriteString(r.output)
		}
	}

	return output.String(), nil
}

// executeOnePrompt runs a single prompt against the diff content.
func (m *Code) executeOnePrompt(
	ctx context.Context,
	moduleDir *dagger.Directory,
	promptPath string,
	diffContent string,
	model string,
	ollamaHost string,
) (string, error) {
	// Load prompt template
	promptContent, err := m.loadPrompt(moduleDir, promptPath, ctx)
	if err != nil {
		return "", err
	}

	// Create files for the container (avoids shell escaping issues)
	diffFile := dag.Directory().
		WithNewFile("diff.txt", diffContent).
		File("diff.txt")

	promptFile := dag.Directory().
		WithNewFile("prompt.txt", promptContent).
		File("prompt.txt")

	// Load the script template from config file
	scriptTemplate, err := moduleDir.File("config/execute-prompt.sh.tmpl").Contents(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to load execute-prompt template: %w", err)
	}

	tmpl, err := template.New("execute").Parse(scriptTemplate)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %w", err)
	}

	var script bytes.Buffer
	err = tmpl.Execute(&script, map[string]string{
		"Model": model,
		"Host":  ollamaHost,
	})
	if err != nil {
		return "", fmt.Errorf("failed to execute template: %w", err)
	}

	return dag.Container().
		From(alpineImage).
		WithExec([]string{"apk", "add", "--no-cache", "curl", "jq"}).
		WithMountedFile("/input/diff.txt", diffFile).
		WithMountedFile("/input/prompt.txt", promptFile).
		WithExec([]string{"sh", "-c", script.String()}).
		Stdout(ctx)
}

// =============================================================================
// Utility Functions
// =============================================================================

// ListPrompts shows all available prompts organized by category.
func (m *Code) ListPrompts(ctx context.Context) (string, error) {
	moduleDir := dag.CurrentModule().Source()
	promptsDirectory := moduleDir.Directory(promptsDir)

	entries, err := promptsDirectory.Entries(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to list prompts directory: %w", err)
	}

	var output strings.Builder
	output.WriteString("Available prompts:\n\n")

	for _, entry := range entries {
		// Skip non-directories and README
		if strings.HasSuffix(entry, ".md") {
			continue
		}

		// List prompts in this category
		categoryDir := promptsDirectory.Directory(entry)
		files, err := categoryDir.Entries(ctx)
		if err != nil {
			continue
		}

		output.WriteString(fmt.Sprintf("## %s\n", entry))
		for _, file := range files {
			if strings.HasPrefix(file, "for-") && strings.HasSuffix(file, ".md") {
				promptName := strings.TrimSuffix(file, ".md")
				fullPath := fmt.Sprintf("%s/%s", strings.TrimSuffix(entry, "/"), promptName)
				output.WriteString(fmt.Sprintf("  - %s\n", fullPath))
			}
		}
		output.WriteString("\n")
	}

	return output.String(), nil
}

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

	// Load the script template from config file
	moduleDir := dag.CurrentModule().Source()
	scriptTemplate, err := moduleDir.File("config/check-ollama.sh.tmpl").Contents(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to load check-ollama template: %w", err)
	}

	tmpl, err := template.New("check").Parse(scriptTemplate)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %w", err)
	}

	var script bytes.Buffer
	err = tmpl.Execute(&script, map[string]string{
		"Host":  ollamaHost,
		"Model": model,
	})
	if err != nil {
		return "", fmt.Errorf("failed to execute template: %w", err)
	}

	return dag.Container().
		From(alpineImage).
		WithExec([]string{"apk", "add", "--no-cache", "curl", "jq"}).
		WithExec([]string{"sh", "-c", script.String()}).
		Stdout(ctx)
}

// =============================================================================
// Internal Helpers
// =============================================================================

// loadPrompt reads a prompt template from the prompts directory.
// promptPath is relative to prompts/, e.g., "review-code/for-basic"
func (m *Code) loadPrompt(moduleDir *dagger.Directory, promptPath string, ctx context.Context) (string, error) {
	// Add .md extension if not present
	if !strings.HasSuffix(promptPath, ".md") {
		promptPath = promptPath + ".md"
	}

	promptFile := moduleDir.File(filepath.Join(promptsDir, promptPath))
	content, err := promptFile.Contents(ctx)
	if err != nil {
		return "", fmt.Errorf("prompt '%s' not found (looking for prompts/%s)", promptPath, promptPath)
	}
	return content, nil
}
