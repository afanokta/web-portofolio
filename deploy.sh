#!/bin/bash

# Deployment script for web-porto
# Usage: ./deploy.sh

set -e

echo "🚀 Starting deployment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Stop existing containers if running
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

# Build and start containers
echo "🔨 Building and starting containers..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d --build
else
    docker compose up -d --build
fi

# Wait a moment for containers to start
sleep 2

# Check if containers are running
if docker ps | grep -q web-porto; then
    echo "✅ Deployment successful!"
    echo "🌐 Your site should be available at http://localhost (or your server IP)"
    echo ""
    echo "Useful commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Stop: docker-compose down"
    echo "  - Restart: docker-compose restart"
else
    echo "❌ Deployment failed. Check logs with: docker-compose logs"
    exit 1
fi

