# Docker Setup for Travel Calculator

This directory contains Docker configuration files for the Travel Calculator Flask application.

## Files

- `Dockerfile` - Multi-stage Docker build configuration
- `.dockerignore` - Files and directories to exclude from Docker build context
- `docker-compose.yml` - Docker Compose configuration for easy deployment

## Quick Start

### Using Docker Compose (Recommended)

1. Build and run the application:
```bash
docker-compose up --build
```

2. Access the application at: http://localhost:8003/travel-calculator/

3. To run in detached mode:
```bash
docker-compose up -d --build
```

4. To stop the application:
```bash
docker-compose down
```

### Using Docker directly

1. Build the image:
```bash
docker build -t travel-calculator .
```

2. Run the container:
```bash
docker run -p 8003:8003 -v $(pwd)/data:/app/data travel-calculator
```

## Features

- **Multi-stage build**: Optimized for production use
- **Security**: Runs as non-root user
- **Health checks**: Built-in health monitoring
- **Volume mounting**: Database persistence through volume mounting
- **Environment variables**: Configurable through environment variables

## Environment Variables

- `FLASK_ENV`: Set to `production` for production mode (default in Docker)
- `PYTHONUNBUFFERED`: Ensures Python output is not buffered (set to 1)

## Database

The application uses SQLite database which is stored in the `/app/data` directory inside the container. When using docker-compose, this is mapped to `./data` on the host for persistence.

## Port

The application runs on port 8003 and is accessible at `/travel-calculator/` path.

## Health Check

The container includes a health check that verifies the application is responding correctly. You can check the health status with:

```bash
docker ps
```

Look for the health status in the STATUS column.