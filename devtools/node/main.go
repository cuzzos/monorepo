// Node toolchain for building Node.js/Next.js frontend projects.
//
// Usage from monorepo root:
//
//	# Production build
//	dagger -m ./devtools/node call build-frontend \
//	  --source=./applications/thiccc/web_frontend \
//	  --env-file=./applications/thiccc/web_frontend/.env.local \
//	  export --path=./applications/thiccc/web_frontend/.next
//
//	# Sync node_modules for IDE support (no local npm required!)
//	dagger -m ./devtools/node call sync-deps --source=./applications/thiccc/web_frontend \
//	  export --path=./applications/thiccc/web_frontend/node_modules
//
// For development server, use Docker Compose: just node-dev
// See also: devtools/node/justfile for simplified commands.

package main

import (
	"dagger/node/internal/dagger"
)

const nodeImage = "node:22-slim"

type Node struct{}

// mountEnvFile mounts an environment file into the container at /app/.env.local.
// Next.js automatically loads .env.local files, so this is the cleanest approach.
// Returns the container with the file mounted, or the original if no file provided.
func mountEnvFile(ctr *dagger.Container, envFile *dagger.File) *dagger.Container {
	if envFile == nil {
		return ctr
	}
	// Mount the env file where Next.js expects it
	return ctr.WithFile("/app/.env.local", envFile)
}

// buildProdContainer is a helper that creates a container with the production build.
func (m *Node) buildProdContainer(source *dagger.Directory, envFile *dagger.File) *dagger.Container {
	ctr := dag.Container().
		From(nodeImage).
		WithDirectory("/app", source).
		WithWorkdir("/app")

	ctr = mountEnvFile(ctr, envFile)

	return ctr.
		WithExec([]string{"npm", "install"}).
		WithExec([]string{"npm", "run", "build"})
}

// BuildFrontend creates an optimized production build.
// Returns the .next directory containing the built application.
func (m *Node) BuildFrontend(
	// Path to the Next.js project directory containing package.json
	source *dagger.Directory,
	// +optional
	// Environment file (e.g., .env.local) containing secrets like API keys
	envFile *dagger.File,
) *dagger.Directory {
	return m.buildProdContainer(source, envFile).
		Directory("/app/.next")
}

// SyncDeps installs npm dependencies and returns the node_modules directory.
// Use this to get IDE IntelliSense without installing npm locally.
// Export the result to your project's node_modules folder.
func (m *Node) SyncDeps(
	// Path to the project directory containing package.json
	source *dagger.Directory,
) *dagger.Directory {
	return dag.Container().
		From(nodeImage).
		WithDirectory("/app", source).
		WithWorkdir("/app").
		WithExec([]string{"npm", "install"}).
		Directory("/app/node_modules")
}
