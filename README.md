# Weather API with OpenTelemetry Integration

This project demonstrates how to implement OpenTelemetry in a .NET API application and monitor it using the OTEL stack (OpenTelemetry Collector, Prometheus, and Grafana).

## Project Structure

- **Weather.API**: A minimal .NET API that provides weather forecast data with SQLite database
- **OpenTelemetry Collector**: Collects metrics and traces from the API
- **Prometheus**: Stores the metrics data
- **Grafana**: Visualizes the metrics and traces

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [Docker](https://www.docker.com/products/docker-desktop/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## How to Run

1. Clone this repository
2. From the root directory, run the following command:

```bash
docker-compose up -d
```

3. Access the services:
   - Weather API: http://localhost:8080/swagger
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (username/password: admin/admin)

## Endpoints

The Weather API provides the following endpoints:

- `GET /weather` - Get all weather forecasts
- `GET /weather/{id}` - Get a specific weather forecast by ID
- `POST /weather` - Create a new weather forecast

## OpenTelemetry Integration

The API uses OpenTelemetry to collect and export:

- **Metrics**: HTTP request counts, durations, process and runtime metrics
- **Traces**: HTTP requests, database operations

The metrics and traces are sent to the OpenTelemetry Collector, which forwards them to Prometheus for storage and Grafana for visualization.

## Architecture

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐     ┌─────────┐
│  Weather.API │────▶│ OTEL Collector  │────▶│  Prometheus  │────▶│ Grafana │
└─────────────┘     └─────────────────┘     └──────────────┘     └─────────┘
        │                                            ▲
        │                                            │
        └────────────────────────────────────────────┘
                        Direct Metrics
