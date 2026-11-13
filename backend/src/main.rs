mod donaciones;
mod error;
mod peticiones;

use std::str::FromStr;

use axum::Router;
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let db_url =
    std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://local.db".to_string());

    let opts = SqliteConnectOptions::from_str(&db_url)?.create_if_missing(true);
    let pool = SqlitePoolOptions::new()
    .max_connections(5)
    .connect_with(opts)
    .await?;

    sqlx::migrate!("./migrations").run(&pool).await?;

    let app = Router::new()
    .nest("/donaciones", donaciones::router())
    .nest("/peticiones", peticiones::router())
    .with_state(pool);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    println!("listening on http://{}", listener.local_addr()?);
    axum::serve(listener, app).await?;
    Ok(())
}
