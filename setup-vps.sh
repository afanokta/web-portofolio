#!/bin/bash

# VPS Setup Script
# Run this script on your VPS to prepare it for deployment

set -e

echo "🚀 Setting up VPS for deployment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Add user to docker group (optional)
if ! groups | grep -q docker; then
    echo "👤 Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "⚠️  You may need to log out and back in for group changes to take effect"
fi

# Create project directory
PROJECT_DIR="$HOME/web-porto"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "📁 Project directory created at $PROJECT_DIR"
echo ""
echo "✅ VPS setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy docker-compose.prod.yml and nginx.conf to $PROJECT_DIR"
echo "2. Configure GitHub Secrets in your repository"
echo "3. Push to main/master branch to trigger deployment"

