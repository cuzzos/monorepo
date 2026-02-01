# Dockerfile for thiccc API server
# Build context: applications/thiccc/ (parent directory)
# Build command: docker build -f api_server/Dockerfile .

# Build stage
FROM rust:1.93-bookworm as builder

WORKDIR /app

# Copy workspace files
COPY Cargo.toml Cargo.lock ./
COPY api_server ./api_server
COPY shared ./shared
COPY shared_types ./shared_types

# Build release binary
RUN cargo build --release --package thiccc-api

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /app/target/release/thiccc-api /usr/local/bin/

# Set environment
ENV RUST_LOG=info
EXPOSE 8000

# Run the binary
CMD ["thiccc-api"]
