#!/bin/bash

# Copy .env if not exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Load .env variables
export $(grep -v '^#' .env | xargs)

# Check if APP_CODE_PATH is set and valid
if [ -z "$APP_CODE_PATH" ]; then
    echo "Error: APP_CODE_PATH is not set in .env"
    exit 1
fi

if [ ! -d "$APP_CODE_PATH" ]; then
    echo "Error: Project path '$APP_CODE_PATH' does not exist."
    exit 1
fi

echo "Deploying project from: $APP_CODE_PATH"

# Convert APP_NAME to lowercase for Docker compatibility
APP_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
export APP_NAME

echo "Project Name: $APP_NAME"
echo "PHP Version: $PHP_VERSION"

# Build and start containers
echo "Building Docker containers..."
docker compose build

echo "Starting deployment..."
docker compose up -d

echo "Waiting for services to initialize..."
sleep 10

# Install dependencies if missing or corrupted
echo "Updating/Installing Composer dependencies..."
# Verify Composer version
echo "Composer Version:"
docker compose exec -T app composer --version

# Force remove old vendor to ensure clean slate for Composer 2 compatibility
docker-compose exec -T app rm -rf vendor composer.lock
docker-compose exec -T app composer install --no-interaction --optimize-autoloader --no-dev
# Fix permissions after install
docker-compose exec -T app chown -R www-data:www-data /var/www/html/vendor

# Run migrations and setup
echo "Running migrations..."
docker compose exec app php artisan migrate --force

# Set permissions
docker compose exec app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "Deployment complete! App running at http://localhost:$APP_PORT"
echo "Check logs with: docker compose logs -f app"
