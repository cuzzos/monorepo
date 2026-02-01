// Rust toolchain for building and running Rust projects.
//
// Usage from monorepo root:
//
//	# Single crate operations
//	dagger -m ./devtools/rust call build-binary --source=./applications/thiccc/api_server
//	dagger -m ./devtools/rust call serve-api --source=./applications/thiccc/api_server up
//
//	# Workspace operations (for projects with multiple crates)
//	dagger -m ./devtools/rust call check-workspace --source=./applications/thiccc
//	dagger -m ./devtools/rust call test-workspace --source=./applications/thiccc
//	dagger -m ./devtools/rust call check-format --source=./applications/thiccc
//	dagger -m ./devtools/rust call run-clippy --source=./applications/thiccc

package main

import (
	"context"

	"dagger/rust/internal/dagger"
)

const rustImage = "rust:1.85-slim"

type Rust struct{}

// baseContainer creates a container with the Rust toolchain and source mounted.
func (m *Rust) baseContainer(source *dagger.Directory) *dagger.Container {
	return dag.Container().
		From(rustImage).
		WithDirectory("/src", source).
		WithWorkdir("/src")
}

// BuildBinary compiles a Rust project and returns the container with build artifacts.
func (m *Rust) BuildBinary(
	// Path to the Rust project directory containing Cargo.toml
	source *dagger.Directory,
	// +optional
	// +default=false
	release bool,
) *dagger.Container {
	args := []string{"cargo", "build"}
	if release {
		args = append(args, "--release")
	}
	return m.baseContainer(source).WithExec(args)
}

// ServeApi builds and runs a Rust API server as a background service.
func (m *Rust) ServeApi(
	// Path to the Rust project directory containing Cargo.toml
	source *dagger.Directory,
	// +optional
	// +default=8000
	port int,
	// +optional
	// +default=false
	release bool,
) *dagger.Service {
	args := []string{"cargo", "run"}
	if release {
		args = append(args, "--release")
	}

	return m.BuildBinary(source, release).
		WithExec(args).
		WithExposedPort(port).
		AsService()
}

// CheckWorkspace runs cargo check on all workspace members.
// Returns the cargo output (includes warnings/errors).
func (m *Rust) CheckWorkspace(
	ctx context.Context,
	// Path to workspace root containing Cargo.toml with [workspace]
	source *dagger.Directory,
) (string, error) {
	return m.baseContainer(source).
		WithExec([]string{"sh", "-c", "cargo check --workspace 2>&1"}).
		Stdout(ctx)
}

// TestWorkspace runs cargo test on all workspace members.
// Returns the test output.
func (m *Rust) TestWorkspace(
	ctx context.Context,
	// Path to workspace root containing Cargo.toml with [workspace]
	source *dagger.Directory,
) (string, error) {
	return m.baseContainer(source).
		WithExec([]string{"sh", "-c", "cargo test --workspace 2>&1"}).
		Stdout(ctx)
}

// CheckFormat checks if code is formatted correctly (fails if not).
// Returns the format check output.
func (m *Rust) CheckFormat(
	ctx context.Context,
	// Path to workspace root containing Cargo.toml
	source *dagger.Directory,
) (string, error) {
	return m.baseContainer(source).
		WithExec([]string{"sh", "-c", "cargo fmt --check 2>&1"}).
		Stdout(ctx)
}

// RunClippy runs the Clippy linter on all workspace members.
// Returns the clippy output (includes warnings).
func (m *Rust) RunClippy(
	ctx context.Context,
	// Path to workspace root containing Cargo.toml with [workspace]
	source *dagger.Directory,
) (string, error) {
	return m.baseContainer(source).
		WithExec([]string{"sh", "-c", "cargo clippy --workspace -- -D warnings 2>&1"}).
		Stdout(ctx)
}
