# SRTLA Dashboard

## Default Ports

- **Dashboard (React frontend):** [http://localhost:3001](http://localhost:3001)
- **Backend (Express API):** http://localhost:8080

## Default Login

- **Username:** admin
- **Password:** adminpass

## Running with Docker Compose

```bash
docker-compose up --build
```

- The dashboard will be available at [http://localhost:3001](http://localhost:3001)
- The dashboard communicates with the backend via `http://backend:8080` inside Docker.

## Environment Variables

Copy `.env.example` files to `.env` in each service as needed and adjust values.
