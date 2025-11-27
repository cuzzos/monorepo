# Thiccc iOS App Makefile

.PHONY: build clean open

# Full build: Rust libs + shared types + Xcode project
build:
	@echo "🔨 Building Rust for iOS..."
	@cd shared && cargo build --release --target aarch64-apple-ios
	@cd shared && cargo build --release --target aarch64-apple-ios-sim
	@echo "🔄 Generating shared types..."
	@cd shared_types && cargo build
	@echo "📱 Generating Xcode project..."
	@cd iOS && ~/.mint/bin/xcodegen generate
	@echo "✅ Build complete!"

clean:
	@cargo clean
	@rm -rf shared/build

open:
	@open iOS/Thiccc.xcodeproj
