#!/bin/bash
# Pre-Handoff Verification Script (Linux/Devcontainer)
# Run this BEFORE pushing code or notifying iOS engineer

set -e  # Exit on any error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "================================"
echo "🔍 Pre-Handoff Verification"
echo "================================"
echo ""
echo "Working directory: $(pwd)"
echo ""

# Step 1: Rust Compilation
echo "1️⃣  Checking Rust compilation..."
cd app/shared
if cargo check --all-targets 2>&1; then
    echo "✅ Rust compiles"
else
    echo "❌ FAILED: Rust compilation errors"
    exit 1
fi
echo ""

# Step 2: Clippy Lints
echo "2️⃣  Running Clippy lints..."
if cargo clippy --all-targets -- -D warnings 2>&1; then
    echo "✅ No Clippy warnings"
else
    echo "❌ FAILED: Clippy found issues"
    echo "💡 Try: cargo clippy --fix --allow-dirty"
    exit 1
fi
echo ""

# Step 3: Tests
echo "3️⃣  Running tests..."
if cargo test --all 2>&1; then
    echo "✅ All tests pass"
else
    echo "❌ FAILED: Tests failed"
    exit 1
fi
echo ""

# Step 4: Code Formatting
echo "4️⃣  Checking code formatting..."
if cargo fmt --check 2>&1; then
    echo "✅ Code is formatted"
else
    echo "⚠️  WARNING: Code formatting issues"
    echo "💡 Run: cargo fmt"
    # Don't fail on formatting, just warn
fi
echo ""

# Step 5: CRITICAL - Swift Type Generation
echo "5️⃣  CRITICAL: Verifying Swift type generation..."
cd ../shared_types
if cargo build 2>&1; then
    echo "✅ Swift types generated successfully"
else
    echo "❌ FAILED: Swift type generation failed"
    echo ""
    echo "⚠️  CRITICAL ERROR: iOS app will crash!"
    echo "Common causes:"
    echo "  - Types with Uuid fields lacking Default implementation"
    echo "  - Complex nested generic types"
    echo "  - Events that can't be traced by serde-reflection"
    echo ""
    echo "Fix this BEFORE iOS engineer tries to build!"
    exit 1
fi
echo ""

# Check for breaking changes
echo "6️⃣  Checking for potential breaking changes..."
cd ../shared

EVENTS_CHANGED=false
if git diff HEAD -- src/app.rs | grep -q "pub enum Event"; then
    EVENTS_CHANGED=true
fi

VIEWMODEL_CHANGED=false
if git diff HEAD -- src/app.rs | grep -q "pub struct ViewModel"; then
    VIEWMODEL_CHANGED=true
fi

if [ "$EVENTS_CHANGED" = true ]; then
    echo "⚠️  Event enum was modified"
    echo "   → Swift code using core.update(.event) may need updates"
fi

if [ "$VIEWMODEL_CHANGED" = true ]; then
    echo "⚠️  ViewModel was modified"
    echo "   → Swift code accessing core.view.X may need updates"
fi

if [ "$EVENTS_CHANGED" = false ] && [ "$VIEWMODEL_CHANGED" = false ]; then
    echo "✅ No breaking changes detected"
fi
echo ""

# Summary
echo "================================"
echo "✅ ALL CHECKS PASSED"
echo "================================"
echo ""

if [ "$EVENTS_CHANGED" = true ] || [ "$VIEWMODEL_CHANGED" = true ]; then
    echo "⚠️  NEXT STEPS:"
    echo "   1. Review breaking changes above"
    echo "   2. Test on macOS (see docs/PRE-HANDOFF-VERIFICATION.md Stage 2)"
    echo "   3. Update Swift code if needed"
else
    echo "✅ Safe to hand off to iOS engineer"
    echo ""
    echo "Optional: Test on macOS to be 100% sure"
    echo "See: docs/PRE-HANDOFF-VERIFICATION.md Stage 2"
fi
echo ""

