// Database toolchain for running PostgreSQL.
//
// Usage from monorepo root:
//
//	dagger -m ./devtools/db call serve-db up
//	dagger -m ./devtools/db call serve-db --database=myapp up

package main

import (
	"dagger/db/internal/dagger"
)

const postgresImage = "postgres:18-alpine"

type Db struct{}

// ServeDb runs a PostgreSQL 18 database as a background service.
// Default credentials: user=postgres, password=postgres
func (m *Db) ServeDb(
	// +optional
	// +default=5432
	port int,
	// +optional
	// +default="postgres"
	database string,
) *dagger.Service {
	return dag.Container().
		From(postgresImage).
		WithEnvVariable("POSTGRES_PASSWORD", "postgres").
		WithEnvVariable("POSTGRES_USER", "postgres").
		WithEnvVariable("POSTGRES_DB", database).
		WithExposedPort(port).
		AsService()
}
