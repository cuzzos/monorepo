use axum::{
    extract::State,
    http::StatusCode,
    routing::get,
    Json, Router,
};
use serde::Serialize;
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

/// Application state shared across handlers
#[derive(Clone)]
struct AppState {
    db: PgPool,
}

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Get database URL from environment
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    // Create database connection pool
    tracing::info!("Connecting to database...");
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to connect to database");

    tracing::info!("Connected to database!");

    let state = AppState { db: pool };

    // CORS layer - allow all for development
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Build router
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/health", get(api_health))
        .layer(cors)
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    // Start server
    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8000);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!("Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

/// Simple health check - just returns OK
async fn health_check() -> &'static str {
    "OK"
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    database: String,
}

/// API health check - verifies database connection
async fn api_health(State(state): State<AppState>) -> Result<Json<HealthResponse>, StatusCode> {
    // Try a simple query to verify DB connection
    let result: Result<(i32,), _> = sqlx::query_as("SELECT 1")
        .fetch_one(&state.db)
        .await;

    match result {
        Ok(_) => Ok(Json(HealthResponse {
            status: "healthy".to_string(),
            database: "connected".to_string(),
        })),
        Err(e) => {
            tracing::error!("Database health check failed: {}", e);
            Ok(Json(HealthResponse {
                status: "unhealthy".to_string(),
                database: format!("error: {}", e),
            }))
        }
    }
}
