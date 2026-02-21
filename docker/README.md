# Finar Docker Deployment

This directory contains Docker configuration for deploying the Finar web app.

## Quick Start

### Using Pre-built Image (from GitLab Container Registry)

```bash
docker run -d -p 8080:80 registry.gitlab.com/openlyst/finar:latest
```

Then open http://localhost:8080 in your browser.

### Building Locally

```bash
# From project root
docker build -f docker/Dockerfile -t finar:latest .

# Run
docker run -d -p 8080:80 finar:latest
```

### Using Docker Compose

```bash
cd docker
docker-compose up -d
```

## CORS Configuration

The web app needs to communicate with your Jellyfin server. There are two ways to handle CORS:

### Option 1: Configure Jellyfin CORS (Recommended for production)

In your Jellyfin server settings, add your Finar web app URL to the CORS origins:

1. Go to Jellyfin Dashboard → Networking
2. Add your Finar URL to "CORS hosts" (e.g., `http://localhost:8080` or `https://finar.yourdomain.com`)

### Option 2: Use nginx Proxy (Development/Simple setups)

Set the `JELLYFIN_URL` environment variable to proxy API requests through nginx:

```bash
docker run -d -p 8080:80 -e JELLYFIN_URL=http://192.168.0.168:30013 finar:latest
```

Or in docker-compose.yml:
```yaml
services:
  finar:
    image: registry.gitlab.com/openlyst/finar:latest
    ports:
      - "8080:80"
    environment:
      - JELLYFIN_URL=http://your-jellyfin-server:8096
```

**Note:** When using proxy mode, the app will use `/api/jellyfin/` prefix for API calls. This feature requires app support for proxy mode.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JELLYFIN_URL` | Jellyfin server URL for proxy mode (optional) | (empty) |

## Reverse Proxy Setup

### nginx

```nginx
server {
    listen 443 ssl;
    server_name finar.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Traefik (with Docker labels)

```yaml
services:
  finar:
    image: registry.gitlab.com/openlyst/finar:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.finar.rule=Host(`finar.yourdomain.com`)"
      - "traefik.http.routers.finar.tls=true"
      - "traefik.http.routers.finar.tls.certresolver=letsencrypt"
```

## Health Check

The container includes a health check endpoint at `/`. You can verify the container is healthy:

```bash
docker inspect --format='{{.State.Health.Status}}' finar
```

## Updating

```bash
docker pull registry.gitlab.com/openlyst/finar:latest
docker-compose down
docker-compose up -d
```
