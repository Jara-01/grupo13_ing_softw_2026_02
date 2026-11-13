use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};

pub struct AppError(pub sqlx::Error);

impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        AppError(e)
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, msg) = match &self.0 {
            sqlx::Error::RowNotFound => (StatusCode::NOT_FOUND, "not found"),
            e if e
            .as_database_error()
            .is_some_and(|d| d.is_unique_violation()) =>
            {
                (StatusCode::CONFLICT, "id already exists")
            }
            e => {
                eprintln!("database error: {e}");
                (StatusCode::INTERNAL_SERVER_ERROR, "internal error")
            }
        };
        (status, Json(serde_json::json!({ "error": msg }))).into_response()
    }
}

pub type AppResult<T> = Result<T, AppError>;
