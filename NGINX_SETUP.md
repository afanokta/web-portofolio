# Nginx Reverse Proxy Setup

Since you have nginx installed on your VPS host, we'll use it as a reverse proxy to the Docker container.

## Architecture

```
Internet → Host Nginx (Port 80/443) → Docker Container (Port 8080)
```

The Docker container runs on `127.0.0.1:8080` (localhost only), and the host nginx proxies requests to it.

## Automatic Setup

The GitHub Actions workflow will automatically:
1. Copy `nginx-vps.conf` to your VPS
2. Place it in `/etc/nginx/sites-available/web-porto`
3. Create a symlink in `/etc/nginx/sites-enabled/`
4. Test and reload nginx

## Manual Setup (If Automatic Fails)

### Step 1: Copy the nginx config

```bash
# On your VPS
cd ~/web-porto
sudo cp nginx-vps.conf /etc/nginx/sites-available/web-porto
```

### Step 2: Enable the site

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/web-porto /etc/nginx/sites-enabled/web-porto

# Remove default nginx site (optional)
sudo rm /etc/nginx/sites-enabled/default
```

### Step 3: Test and reload

```bash
# Test configuration
sudo nginx -t

# If test passes, reload nginx
sudo systemctl reload nginx
# or
sudo service nginx reload
```

## Verify Setup

1. **Check container is running:**
   ```bash
   docker ps | grep web-porto
   # Should show container running on 127.0.0.1:8080->80/tcp
   ```

2. **Check nginx is proxying:**
   ```bash
   curl http://localhost:8080
   # Should return your app content
   ```

3. **Check from outside:**
   ```bash
   curl http://your-vps-ip
   # Should return your app content
   ```

## Custom Domain Setup

If you have a domain name:

1. **Edit the nginx config:**
   ```bash
   sudo nano /etc/nginx/sites-available/web-porto
   ```

2. **Replace `server_name _;` with your domain:**
   ```nginx
   server_name yourdomain.com www.yourdomain.com;
   ```

3. **Reload nginx:**
   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   ```

## SSL/HTTPS Setup (Let's Encrypt)

1. **Install certbot:**
   ```bash
   sudo apt update
   sudo apt install certbot python3-certbot-nginx -y
   ```

2. **Get SSL certificate:**
   ```bash
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

3. **Uncomment HTTPS section in nginx config:**
   ```bash
   sudo nano /etc/nginx/sites-available/web-porto
   # Uncomment the SSL server block
   ```

4. **Reload nginx:**
   ```bash
   sudo nginx -t && sudo systemctl reload nginx
   ```

## Troubleshooting

### Port 80 already in use

If you see errors about port 80 being in use:

```bash
# Check what's using port 80
sudo netstat -tulpn | grep :80
sudo ss -tulpn | grep :80

# Stop conflicting service (if not nginx)
sudo systemctl stop apache2  # if Apache is running
```

### Container not accessible

1. **Check container is running:**
   ```bash
   docker ps | grep web-porto
   ```

2. **Check container logs:**
   ```bash
   docker logs web-porto
   ```

3. **Test container directly:**
   ```bash
   curl http://127.0.0.1:8080
   ```

### Nginx configuration errors

1. **Test configuration:**
   ```bash
   sudo nginx -t
   ```

2. **Check nginx error logs:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Check nginx access logs:**
   ```bash
   sudo tail -f /var/log/nginx/access.log
   ```

## Multiple Sites

If you want to host multiple sites:

1. Create separate nginx configs for each site
2. Use different `server_name` directives
3. Keep Docker containers on different localhost ports (8080, 8081, etc.)

Example:
```nginx
# Site 1
server {
    listen 80;
    server_name site1.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}

# Site 2
server {
    listen 80;
    server_name site2.com;
    location / {
        proxy_pass http://127.0.0.1:8081;
    }
}
```

## Benefits of This Setup

1. **SSL/TLS termination** - Host nginx handles HTTPS
2. **Multiple sites** - Easy to add more applications
3. **Security** - Container only exposed to localhost
4. **Performance** - Nginx is efficient at proxying
5. **Flexibility** - Easy to add rate limiting, caching, etc.

