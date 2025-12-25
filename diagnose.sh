#!/bin/bash

# Diagnostic script to check deployment status
# Run this on your VPS: ./diagnose.sh

echo "🔍 Diagnosing Deployment Issues"
echo "================================"
echo ""

# Check container status
echo "1. Checking Docker container..."
if docker ps | grep -q web-porto; then
    echo "✅ Container is running"
    docker ps --filter "name=web-porto" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "❌ Container is not running"
    exit 1
fi

echo ""
echo "2. Checking container files..."
if docker exec web-porto test -f /usr/share/nginx/html/index.html 2>/dev/null; then
    echo "✅ index.html exists in container"
    docker exec web-porto ls -la /usr/share/nginx/html/ | head -10
else
    echo "❌ index.html NOT found in container"
    echo "   Container might not have built files"
fi

echo ""
echo "3. Testing container directly (localhost:8080)..."
if curl -s http://127.0.0.1:8080 | head -5; then
    echo "✅ Container is serving content on localhost:8080"
else
    echo "❌ Container is NOT responding on localhost:8080"
fi

echo ""
echo "4. Checking host nginx configuration..."
if [ -f /etc/nginx/sites-available/web-porto ]; then
    echo "✅ Nginx config file exists"
    if [ -L /etc/nginx/sites-enabled/web-porto ]; then
        echo "✅ Nginx site is enabled"
    else
        echo "⚠️  Nginx site is NOT enabled (symlink missing)"
        echo "   Run: sudo ln -s /etc/nginx/sites-available/web-porto /etc/nginx/sites-enabled/web-porto"
    fi
else
    echo "❌ Nginx config file NOT found at /etc/nginx/sites-available/web-porto"
    echo "   You need to set up nginx reverse proxy"
fi

echo ""
echo "5. Checking nginx status..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
    if sudo nginx -t 2>&1 | grep -q "successful"; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration has errors:"
        sudo nginx -t
    fi
else
    echo "❌ Nginx is NOT running"
    echo "   Run: sudo systemctl start nginx"
fi

echo ""
echo "6. Checking what's listening on port 80..."
if sudo netstat -tulpn | grep :80 || sudo ss -tulpn | grep :80; then
    echo "✅ Something is listening on port 80"
else
    echo "⚠️  Nothing is listening on port 80"
fi

echo ""
echo "7. Testing from outside (port 80)..."
if curl -s http://localhost | head -5; then
    echo "✅ Port 80 is responding"
else
    echo "❌ Port 80 is NOT responding"
fi

echo ""
echo "================================"
echo "Diagnosis complete!"
echo ""
echo "If container works on :8080 but not on :80, you need to:"
echo "1. Copy nginx-vps.conf to /etc/nginx/sites-available/web-porto"
echo "2. Enable it: sudo ln -s /etc/nginx/sites-available/web-porto /etc/nginx/sites-enabled/web-porto"
echo "3. Remove default site: sudo rm /etc/nginx/sites-enabled/default"
echo "4. Test: sudo nginx -t"
echo "5. Reload: sudo systemctl reload nginx"

