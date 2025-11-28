# Thiccc iOS App Makefile

# Configurable simulator (can override: make run-sim SIMULATOR="iPhone 17")
SIMULATOR ?= iPhone 16 Pro

.PHONY: build clean open xcode-build run-sim list-sims test check help close-sims

# Default target: show help
.DEFAULT_GOAL := help

# Show help
help:
	@echo "Thiccc iOS App Build Commands"
	@echo ""
	@echo "Main commands:"
	@echo "  make build       - Build Rust libraries and generate Xcode project"
	@echo "  make xcode-build - Build Rust + iOS app (no Xcode GUI)"
	@echo "  make run-sim     - Build and run in simulator"
	@echo "  make test        - Run tests"
	@echo "  make open        - Open Xcode project"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "Utilities:"
	@echo "  make check       - Check if everything is set up correctly"
	@echo "  make list-sims   - List available iOS simulators"
	@echo "  make close-sims  - Close all running simulators"
	@echo "  make help        - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  SIMULATOR        - Choose simulator (default: $(SIMULATOR))"
	@echo ""
	@echo "Examples:"
	@echo "  make run-sim SIMULATOR=\"iPhone 16\""
	@echo "  make test SIMULATOR=\"iPhone Air\""
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
	@cd iOS && mint run xcodegen xcodegen generate
	@echo "✅ Build complete!"

# Build iOS app using xcodebuild (no Xcode GUI needed)
xcode-build: build
	@echo "🍎 Building iOS app for simulator..."
	@echo "📱 Target: $(SIMULATOR)"
	@echo "⏳ This may take a minute on first build..."
	@xcodebuild -project iOS/Thiccc.xcodeproj \
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
	@echo "▶️  Launching app..."
	@xcrun simctl launch --console booted com.cuzzos.Thiccc.Thiccc

# List available simulators
list-sims:
	@echo "Available iOS Simulators:"
	@xcrun simctl list devices available iOS | grep "iPhone\|iPad" || echo "Run 'open /Applications/Xcode.app' to install simulators"

# Run tests
test: build
	@echo "🧪 Running tests on $(SIMULATOR)..."
	@xcodebuild -project iOS/Thiccc.xcodeproj \
		-scheme Thiccc \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		test

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

clean:
	@cargo clean
	@rm -rf shared/build
	@rm -rf iOS/build

open:
	@open iOS/Thiccc.xcodeproj
