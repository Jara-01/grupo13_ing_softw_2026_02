CREATE TABLE donaciones (
  id TEXT PRIMARY KEY,
  tipoSangre TEXT NOT NULL,
  centroOrigen TEXT NOT NULL,
  fechaLlegada TEXT NOT NULL,
  fechaVencimiento TEXT NOT NULL,
  volumenMl INTEGER NOT NULL,
  estado TEXT NOT NULL
);

CREATE TABLE peticiones (
  id TEXT PRIMARY KEY,
  centroSolicitante TEXT NOT NULL,
  tipoSangre TEXT NOT NULL,
  cantidad INTEGER NOT NULL,
  estado TEXT NOT NULL
);

