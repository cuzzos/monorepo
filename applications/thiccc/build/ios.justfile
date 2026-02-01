# iOS Development Commands

default:
    @just --list ios

# Build and run iOS app in simulator
run:
    make -C .. -f build/Makefile run-sim

# Run Rust tests (fast)
test:
    make -C .. -f build/Makefile test-rust

# Full verification (tests + coverage + types)
verify:
    make -C .. -f build/Makefile verify-agent
