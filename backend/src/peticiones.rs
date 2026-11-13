use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::get,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;

use crate::error::{AppError, AppResult};

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
#[sqlx(rename_all = "camelCase")]
pub struct Peticion {
    id: String,
    centro_solicitante: String,
    tipo_sangre: String,
    cantidad: i64,
    estado: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreatePeticion {
    /// Optional: a UUID is generated if omitted.
    id: Option<String>,
    centro_solicitante: String,
    tipo_sangre: String,
    cantidad: i64,
    estado: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatePeticion {
    centro_solicitante: Option<String>,
    tipo_sangre: Option<String>,
    cantidad: Option<i64>,
    estado: Option<String>,
}

const COLS: &str = "id, centroSolicitante, tipoSangre, cantidad, estado";

pub fn router() -> Router<SqlitePool> {
    Router::new()
    .route("/", get(list).post(create))
    .route("/{id}", get(get_one).patch(update).delete(remove))
}

async fn list(State(pool): State<SqlitePool>) -> AppResult<Json<Vec<Peticion>>> {
    let rows = sqlx::query_as::<_, Peticion>(&format!("SELECT {COLS} FROM peticiones ORDER BY id"))
    .fetch_all(&pool)
    .await?;
    Ok(Json(rows))
}

async fn get_one(
    State(pool): State<SqlitePool>,
                 Path(id): Path<String>,
) -> AppResult<Json<Peticion>> {
    let row = sqlx::query_as::<_, Peticion>(&format!("SELECT {COLS} FROM peticiones WHERE id = ?"))
    .bind(id)
    .fetch_one(&pool)
    .await?;
    Ok(Json(row))
}

async fn create(
    State(pool): State<SqlitePool>,
                Json(b): Json<CreatePeticion>,
) -> AppResult<(StatusCode, Json<Peticion>)> {
    let id = b.id.unwrap_or_else(|| Uuid::new_v4().to_string());
    let row = sqlx::query_as::<_, Peticion>(&format!(
        "INSERT INTO peticiones (id, centroSolicitante, tipoSangre, cantidad, estado)
    VALUES (?, ?, ?, ?, ?)
    RETURNING {COLS}"
    ))
    .bind(id)
    .bind(b.centro_solicitante)
    .bind(b.tipo_sangre)
    .bind(b.cantidad)
    .bind(b.estado)
    .fetch_one(&pool)
    .await?;
    Ok((StatusCode::CREATED, Json(row)))
}

async fn update(
    State(pool): State<SqlitePool>,
                Path(id): Path<String>,
                Json(b): Json<UpdatePeticion>,
) -> AppResult<Json<Peticion>> {
    let row = sqlx::query_as::<_, Peticion>(&format!(
        "UPDATE peticiones SET
        centroSolicitante = COALESCE(?, centroSolicitante),
                                                     tipoSangre        = COALESCE(?, tipoSangre),
                                                     cantidad          = COALESCE(?, cantidad),
                                                     estado            = COALESCE(?, estado)
    WHERE id = ?
    RETURNING {COLS}"
    ))
    .bind(b.centro_solicitante)
    .bind(b.tipo_sangre)
    .bind(b.cantidad)
    .bind(b.estado)
    .bind(id)
    .fetch_one(&pool)
    .await?;
    Ok(Json(row))
}

async fn remove(
    State(pool): State<SqlitePool>,
                Path(id): Path<String>,
) -> AppResult<StatusCode> {
    let res = sqlx::query("DELETE FROM peticiones WHERE id = ?")
    .bind(id)
    .execute(&pool)
    .await?;
    if res.rows_affected() == 0 {
        return Err(AppError(sqlx::Error::RowNotFound));
    }
    Ok(StatusCode::NO_CONTENT)
}
