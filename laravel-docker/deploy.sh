#!/bin/bash

# Copy .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env created from .env.example"
fi

# Build and start containers
echo "Building Docker containers..."
docker-compose build

echo "Starting deployment..."
docker-compose up -d

# Wait for database to be ready (optional check could be added)
echo "Waiting for services to initialize..."
sleep 10

# Run migrations and setup
echo "Running migrations..."
docker-compose exec app php artisan migrate --force

# Set permissions
docker-compose exec app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "Deployment complete! App running at http://localhost:8000"
echo "Check logs with: docker-compose logs -f app"
