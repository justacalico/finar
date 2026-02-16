# Multi-stage build for Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy the entire project
COPY . .

# Get dependencies
RUN flutter pub get --no-precompile

# Run build_runner for code generation
RUN dart run build_runner build --delete-conflicting-outputs

# Build web release
RUN flutter build web --release

# Production stage - nginx to serve the app
FROM nginx:alpine

# Install envsubst for environment variable substitution
RUN apk add --no-cache gettext

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration template
COPY docker/nginx.conf.template /etc/nginx/templates/default.conf.template

# Copy entrypoint script
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
