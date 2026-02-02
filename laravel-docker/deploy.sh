#!/bin/bash
set -e

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
sleep 5

# Install dependencies
echo "Updating/Installing Composer dependencies..."

# Force remove corrupted lock/vendor if they exist to ensure clean slate
docker compose exec -T app rm -rf vendor composer.lock

# Robustly patch composer.json for Laravel 5.5 + Composer 2 compatibility
echo "Applying compatibility patches to composer.json..."
docker compose exec -T app php -r '
    $path = "composer.json";
    $json = json_decode(file_get_contents($path), true);
    // Fix framework version
    if (isset($json["require"]["laravel/framework"])) {
        $json["require"]["laravel/framework"] = "5.5.*";
    }
    // Allow necessary plugins
    $json["config"]["allow-plugins"] = [
        "kylekatarnls/update-helper" => true,
        "symfony/thanks" => true
    ];
    file_put_contents($path, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
'

docker compose exec -T app composer install --no-interaction --optimize-autoloader --no-dev

# Run migrations and setup
echo "Running migrations..."
docker compose exec -T app php artisan migrate --force

# Set permissions
echo "Setting permissions..."
docker compose exec -T app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "Deployment complete! App running at http://localhost:$APP_PORT"
echo "Check logs with: docker compose logs -f app"
