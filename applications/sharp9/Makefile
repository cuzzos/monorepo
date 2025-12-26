# Sharp9 iOS App Makefile

# Configurable simulator (can override: make run-sim SIMULATOR='iPhone 17')
SIMULATOR ?= iPhone 17 Pro

.PHONY: build clean open xcode-build run-sim list-sims test check help close-sims logs logs-all

# Default target: show help
.DEFAULT_GOAL := help

# Show help
help:
	@echo "Sharp9 iOS App Build Commands"
	@echo ""
	@echo "Main commands:"
	@echo "  make build       - Generate Xcode project from project.yml"
	@echo "  make xcode-build - Build iOS app (no Xcode GUI)"
	@echo "  make run-sim     - Build and run in simulator (filtered logs)"
	@echo "  make test        - Run tests in simulator"
	@echo "  make open        - Open Xcode project"
	@echo "  make clean       - Clean build artifacts"
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
	@echo "  make test SIMULATOR='iPhone SE'"
	@echo ""
	@echo "Current settings:"
	@echo "  Simulator: $(SIMULATOR)"

# Generate Xcode project using XcodeGen
build:
	@echo "📱 Generating Xcode project..."
	@cd app/iOS && mint run xcodegen xcodegen generate
	@echo "✅ Xcode project generated!"

# Build iOS app using xcodebuild (no Xcode GUI needed)
xcode-build: build
	@echo "🍎 Building iOS app for simulator..."
	@echo "📱 Target: $(SIMULATOR)"
	@echo "⏳ This may take a minute on first build..."
	@xcodebuild -project app/iOS/Sharp9.xcodeproj \
		-scheme Sharp9 \
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
	@APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData/Sharp9-*/Build/Products/Debug-iphonesimulator -name "Sharp9.app" -type d 2>/dev/null | head -1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "❌ Could not find Sharp9.app in DerivedData"; \
		echo "Searching for it..."; \
		find ~/Library/Developer/Xcode/DerivedData -name "Sharp9.app" -type d 2>/dev/null | head -5; \
		exit 1; \
	fi; \
	echo "Found app at: $$APP_PATH"; \
	xcrun simctl install booted "$$APP_PATH"
	@echo "▶️  Launching app and streaming logs..."
	@echo "📋 Press Ctrl+C to stop watching logs"
	@xcrun simctl launch booted com.cuzzos.Sharp9 &
	@sleep 1
	@xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath CONTAINS "Sharp9"' --style compact

# List available simulators
list-sims:
	@echo "Available iOS Simulators:"
	@xcrun simctl list devices available iOS | grep "iPhone\|iPad" || echo "Run 'open /Applications/Xcode.app' to install simulators"

# Run tests in simulator
test: build
	@echo "🧪 Running tests on $(SIMULATOR)..."
	@xcodebuild -project app/iOS/Sharp9.xcodeproj \
		-scheme Sharp9 \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		test

# Check if everything is set up correctly
check:
	@echo "🔍 Checking build environment..."
	@command -v xcodegen >/dev/null 2>&1 && echo "✅ XcodeGen installed" || echo "❌ XcodeGen not found (run: brew install xcodegen)"
	@command -v mint >/dev/null 2>&1 && echo "✅ Mint installed" || echo "❌ Mint not found (run: brew install mint)"
	@command -v xcodebuild >/dev/null 2>&1 && echo "✅ Xcode Command Line Tools" || echo "❌ Xcode not found"
	@echo ""
	@echo "Available simulators:"
	@xcrun simctl list devices available iOS 2>/dev/null | grep "iPhone\|iPad" | head -5 || echo "⚠️  No simulators found - open Xcode to install"

# Close all running simulators
close-sims:
	@echo "🛑 Shutting down all simulators..."
	@xcrun simctl shutdown all
	@killall Simulator 2>/dev/null || true
	@echo "✅ All simulators closed"

# Stream logs from running app (filtered to Sharp9)
logs:
	@echo "📋 Streaming logs from Sharp9 app (filtered)..."
	@echo "Press Ctrl+C to stop"
	@xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath CONTAINS "Sharp9"' --style compact

# Stream ALL system logs (unfiltered)
logs-all:
	@echo "📋 Streaming ALL system logs (unfiltered)..."
	@echo "⚠️  This will be very verbose!"
	@echo "Press Ctrl+C to stop"
	@xcrun simctl spawn booted log stream --level=debug --style compact

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf app/iOS/build
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Sharp9-*
	@rm -f xcodebuild.log
	@echo "✅ Clean complete!"

# Open Xcode project
open: build
	@open app/iOS/Sharp9.xcodeproj


