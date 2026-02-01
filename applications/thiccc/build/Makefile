# Thiccc iOS App Makefile
# Run from thiccc/ root: make -f build/Makefile <target>

# Configurable simulator (can override: make run-sim SIMULATOR='iPhone 17')
SIMULATOR ?= iPhone 16 Pro

.PHONY: build clean open xcode-build run-sim list-sims test check help close-sims logs logs-all run-sim-all coverage coverage-report coverage-check test-rust verify-agent

# Default target: show help
.DEFAULT_GOAL := help

# Show help
help:
	@echo "Thiccc iOS App Build Commands"
	@echo ""
	@echo "Main commands:"
	@echo "  make build       - Build Rust libraries and generate Xcode project"
	@echo "  make xcode-build - Build Rust + iOS app (no Xcode GUI)"
	@echo "  make run-sim     - Build and run in simulator (filtered logs)"
	@echo "  make run-sim-all - Build and run in simulator (all system logs)"
	@echo "  make test        - Run tests"
	@echo "  make open        - Open Xcode project"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "Testing & Coverage:"
	@echo "  make test-rust       - Run Rust unit tests only"
	@echo "  make coverage        - Run tests with coverage report (HTML)"
	@echo "  make coverage-report - Open coverage HTML report in browser"
	@echo "  make coverage-check  - Verify 100% line coverage (CI-ready)"
	@echo "  make verify-agent    - Complete validation for AI agents (fast)"
	@echo ""
	@echo "Utilities:"
	@echo "  make check       - Check if everything is set up correctly"
	@echo "  make list-sims   - List available iOS simulators"
	@echo "  make logs        - Stream logs from running app (filtered)"
	@echo "  make logs-all    - Stream ALL system logs (unfiltered)"
	@echo "  make close-sims  - Close all running simulators"
	@echo "  make help        - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  SIMULATOR        - Choose simulator (default: $(SIMULATOR))"
	@echo ""
	@echo "Examples:"
	@echo "  make run-sim SIMULATOR='iPhone 16'"
	@echo "  make test SIMULATOR='iPhone Air'"
	@echo "  make coverage-check  # Verify 100% Rust coverage"
	@echo ""
	@echo "Current settings:"
	@echo "  Simulator: $(SIMULATOR)"

# Full build: Rust libs + shared types + Xcode project
build:
	@echo "🔄 Generating shared types..."
	@cd shared_types && cargo build
	@echo "🔨 Building Rust for iOS..."
	@cd shared && cargo build --release --target aarch64-apple-ios
	@cd shared && cargo build --release --target aarch64-apple-ios-sim
	@echo "📱 Generating Xcode project..."
	@cd ios && mint run xcodegen xcodegen generate
	@echo "✅ Build complete!"

# Build iOS app using xcodebuild (no Xcode GUI needed)
xcode-build: build
	@echo "🍎 Building iOS app for simulator..."
	@echo "📱 Target: $(SIMULATOR)"
	@echo "⏳ This may take a minute on first build..."
	@xcodebuild -project ios/Thiccc.xcodeproj \
		-scheme Thiccc \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-configuration Debug \
		-showBuildTimingSummary \
		build | tee xcodebuild.log | grep -E "^\*\*|Building|Linking|⚠️|error:|warning:"
	@echo "✅ iOS app build complete!"

# Build and run in simulator
run-sim: xcode-build
	@echo "🛑 Shutting down any running simulators..."
	@xcrun simctl shutdown all 2>/dev/null || true
	@echo "🚀 Booting simulator: $(SIMULATOR)..."
	@xcrun simctl boot "$(SIMULATOR)"
	@open -a Simulator
	@sleep 2
	@echo "📲 Installing app..."
	@APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData/Thiccc-*/Build/Products/Debug-iphonesimulator -name "Thiccc.app" -type d 2>/dev/null | head -1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "❌ Could not find Thiccc.app in DerivedData"; \
		echo "Searching for it..."; \
		find ~/Library/Developer/Xcode/DerivedData -name "Thiccc.app" -type d 2>/dev/null | head -5; \
		exit 1; \
	fi; \
	echo "Found app at: $$APP_PATH"; \
	xcrun simctl install booted "$$APP_PATH"
	@echo "▶️  Launching app and streaming logs..."
	@echo "📋 Press Ctrl+C to stop watching logs"
	@xcrun simctl launch booted com.cuzzos.Thiccc.Thiccc &
	@sleep 1
	@xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath CONTAINS "Thiccc"' --style compact

# Build and run in simulator with ALL system logs (unfiltered)
run-sim-all: xcode-build
	@echo "🛑 Shutting down any running simulators..."
	@xcrun simctl shutdown all 2>/dev/null || true
	@echo "🚀 Booting simulator: $(SIMULATOR)..."
	@xcrun simctl boot "$(SIMULATOR)"
	@open -a Simulator
	@sleep 2
	@echo "📲 Installing app..."
	@APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData/Thiccc-*/Build/Products/Debug-iphonesimulator -name "Thiccc.app" -type d 2>/dev/null | head -1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "❌ Could not find Thiccc.app in DerivedData"; \
		echo "Searching for it..."; \
		find ~/Library/Developer/Xcode/DerivedData -name "Thiccc.app" -type d 2>/dev/null | head -5; \
		exit 1; \
	fi; \
	echo "Found app at: $$APP_PATH"; \
	xcrun simctl install booted "$$APP_PATH"
	@echo "▶️  Launching app and streaming ALL logs..."
	@echo "⚠️  This will be very verbose!"
	@echo "📋 Press Ctrl+C to stop watching logs"
	@xcrun simctl launch booted com.cuzzos.Thiccc.Thiccc &
	@sleep 1
	@xcrun simctl spawn booted log stream --level=debug --style compact

# List available simulators
list-sims:
	@echo "Available iOS Simulators:"
	@xcrun simctl list devices available iOS | grep "iPhone\|iPad" || echo "Run 'open /Applications/Xcode.app' to install simulators"

# Run Rust unit tests only (fast)
test-rust:
	@echo "🧪 Running Rust unit tests..."
	@cd shared && cargo test --all-features
	@echo "✅ Rust tests passed!"

# Run iOS tests in simulator (slower)
test: build
	@echo "🧪 Running tests on $(SIMULATOR)..."
	@xcodebuild -project ios/Thiccc.xcodeproj \
		-scheme Thiccc \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		test

# Run tests with coverage and generate HTML report
coverage:
	@echo "🧪 Running tests with coverage..."
	@if ! command -v cargo-llvm-cov >/dev/null 2>&1; then \
		echo "❌ cargo-llvm-cov not found. Installing..."; \
		cargo install cargo-llvm-cov; \
	fi
	@cd shared && cargo llvm-cov --all-features --workspace --html
	@echo "✅ Coverage report generated!"
	@echo "📊 View report: make coverage-report"
	@echo "    or open: shared/target/llvm-cov/html/index.html"

# Open coverage HTML report in browser
coverage-report:
	@echo "📊 Opening coverage report..."
	@if [ ! -f shared/target/llvm-cov/html/index.html ]; then \
		echo "❌ Coverage report not found. Run 'make coverage' first."; \
		exit 1; \
	fi
	@open shared/target/llvm-cov/html/index.html

# Check if coverage meets 100% threshold (fails if below)
coverage-check:
	@echo "🧪 Running tests with coverage..."
	@if ! command -v cargo-llvm-cov >/dev/null 2>&1; then \
		echo "❌ cargo-llvm-cov not found. Installing..."; \
		cargo install cargo-llvm-cov; \
	fi
	@echo "🔍 Checking coverage threshold (100% line coverage required)..."
	@cd shared && cargo llvm-cov --all-features --workspace --fail-under-lines 100 --ignore-filename-regex "lib.rs"
	@echo "✅ Coverage meets 100% threshold!"

# Check if everything is set up correctly
check:
	@echo "🔍 Checking build environment..."
	@command -v cargo >/dev/null 2>&1 && echo "✅ Rust/Cargo installed" || echo "❌ Rust not found"
	@command -v xcodegen >/dev/null 2>&1 && echo "✅ XcodeGen installed" || echo "❌ XcodeGen not found"
	@command -v xcodebuild >/dev/null 2>&1 && echo "✅ Xcode Command Line Tools" || echo "❌ Xcode not found"
	@rustup target list --installed | grep -q "aarch64-apple-ios" && echo "✅ iOS target (device)" || echo "❌ iOS device target missing"
	@rustup target list --installed | grep -q "aarch64-apple-ios-sim" && echo "✅ iOS target (simulator)" || echo "❌ iOS simulator target missing"
	@echo ""
	@echo "Available simulators:"
	@xcrun simctl list devices available iOS 2>/dev/null | grep "iPhone\|iPad" | head -5 || echo "⚠️  No simulators found - open Xcode to install"

# Close all running simulators
close-sims:
	@echo "🛑 Shutting down all simulators..."
	@xcrun simctl shutdown all
	@killall Simulator 2>/dev/null || true
	@echo "✅ All simulators closed"

# Stream logs from running app (filtered to Thiccc)
logs:
	@echo "📋 Streaming logs from Thiccc app (filtered)..."
	@echo "Press Ctrl+C to stop"
	@xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath CONTAINS "Thiccc"' --style compact

# Stream ALL system logs (unfiltered)
logs-all:
	@echo "📋 Streaming ALL system logs (unfiltered)..."
	@echo "⚠️  This will be very verbose!"
	@echo "Press Ctrl+C to stop"
	@xcrun simctl spawn booted log stream --level=debug --style compact

clean:
	@cargo clean
	@rm -rf shared/build
	@rm -rf ios/build

open:
	@open ios/Thiccc.xcodeproj

# Agent-optimized validation (fast, comprehensive)
verify-agent:
	@echo "🤖 Running AI Agent Validation..."
	@echo ""
	@echo "1️⃣  Running Rust tests..."
	@cd shared && cargo test --all-features --quiet
	@echo "✅ Tests passed"
	@echo ""
	@echo "2️⃣  Checking code coverage..."
	@if ! command -v cargo-llvm-cov >/dev/null 2>&1; then \
		echo "⚠️  cargo-llvm-cov not found. Installing..."; \
		cargo install cargo-llvm-cov; \
	fi
	@cd shared && cargo llvm-cov --all-features --workspace --fail-under-lines 100 --ignore-filename-regex "lib.rs" --quiet
	@echo "✅ 100% coverage achieved"
	@echo ""
	@echo "3️⃣  Generating Swift types..."
	@cd shared_types && cargo build --quiet 2>&1 | grep -v "Compiling\|Finished" || true
	@echo "✅ Swift types generated"
	@echo ""
	@echo "================================"
	@echo "✅ ALL AGENT CHECKS PASSED"
	@echo "================================"
	@echo ""
	@echo "Ready to hand off to user!"
	@echo ""
