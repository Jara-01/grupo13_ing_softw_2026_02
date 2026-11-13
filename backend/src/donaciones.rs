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
pub struct Donacion {
    id: String,
    tipo_sangre: String,
    centro_origen: String,
    fecha_llegada: String,
    fecha_vencimiento: String,
    volumen_ml: i64,
    estado: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateDonacion {
    /// Optional: a UUID is generated if omitted.
    id: Option<String>,
    tipo_sangre: String,
    centro_origen: String,
    fecha_llegada: String,
    fecha_vencimiento: String,
    volumen_ml: i64,
    estado: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateDonacion {
    tipo_sangre: Option<String>,
    centro_origen: Option<String>,
    fecha_llegada: Option<String>,
    fecha_vencimiento: Option<String>,
    volumen_ml: Option<i64>,
    estado: Option<String>,
}

const COLS: &str =
"id, tipoSangre, centroOrigen, fechaLlegada, fechaVencimiento, volumenMl, estado";

pub fn router() -> Router<SqlitePool> {
    Router::new()
    .route("/", get(list).post(create))
    .route("/{id}", get(get_one).patch(update).delete(remove))
}

async fn list(State(pool): State<SqlitePool>) -> AppResult<Json<Vec<Donacion>>> {
    let rows = sqlx::query_as::<_, Donacion>(&format!("SELECT {COLS} FROM donaciones ORDER BY id"))
    .fetch_all(&pool)
    .await?;
    Ok(Json(rows))
}

async fn get_one(
    State(pool): State<SqlitePool>,
                 Path(id): Path<String>,
) -> AppResult<Json<Donacion>> {
    let row = sqlx::query_as::<_, Donacion>(&format!("SELECT {COLS} FROM donaciones WHERE id = ?"))
    .bind(id)
    .fetch_one(&pool)
    .await?;
    Ok(Json(row))
}

async fn create(
    State(pool): State<SqlitePool>,
                Json(b): Json<CreateDonacion>,
) -> AppResult<(StatusCode, Json<Donacion>)> {
    let id = b.id.unwrap_or_else(|| Uuid::new_v4().to_string());
    let row = sqlx::query_as::<_, Donacion>(&format!(
        "INSERT INTO donaciones
        (id, tipoSangre, centroOrigen, fechaLlegada, fechaVencimiento, volumenMl, estado)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    RETURNING {COLS}"
    ))
    .bind(id)
    .bind(b.tipo_sangre)
    .bind(b.centro_origen)
    .bind(b.fecha_llegada)
    .bind(b.fecha_vencimiento)
    .bind(b.volumen_ml)
    .bind(b.estado)
    .fetch_one(&pool)
    .await?;
    Ok((StatusCode::CREATED, Json(row)))
}

async fn update(
    State(pool): State<SqlitePool>,
                Path(id): Path<String>,
                Json(b): Json<UpdateDonacion>,
) -> AppResult<Json<Donacion>> {
    let row = sqlx::query_as::<_, Donacion>(&format!(
        "UPDATE donaciones SET
        tipoSangre       = COALESCE(?, tipoSangre),
                                                     centroOrigen     = COALESCE(?, centroOrigen),
                                                     fechaLlegada     = COALESCE(?, fechaLlegada),
                                                     fechaVencimiento = COALESCE(?, fechaVencimiento),
                                                     volumenMl        = COALESCE(?, volumenMl),
                                                     estado           = COALESCE(?, estado)
    WHERE id = ?
    RETURNING {COLS}"
    ))
    .bind(b.tipo_sangre)
    .bind(b.centro_origen)
    .bind(b.fecha_llegada)
    .bind(b.fecha_vencimiento)
    .bind(b.volumen_ml)
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
    let res = sqlx::query("DELETE FROM donaciones WHERE id = ?")
    .bind(id)
    .execute(&pool)
    .await?;
    if res.rows_affected() == 0 {
        return Err(AppError(sqlx::Error::RowNotFound));
    }
    Ok(StatusCode::NO_CONTENT)
}
