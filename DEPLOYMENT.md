# Deployment Guide

This project uses GitHub Actions for CI/CD to automatically build and deploy to your VPS.

## Setup Instructions

### 1. GitHub Secrets Configuration

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add the following secrets:

#### Required Secrets:

- **`VPS_HOST`**: Your VPS IP address or domain (e.g., `192.168.1.100` or `example.com`)
- **`VPS_USER`**: SSH username for your VPS (e.g., `ubuntu` or `root`)
- **`VPS_SSH_KEY`**: Your private SSH key for accessing the VPS
  - Generate with: `ssh-keygen -t ed25519 -C "github-actions"`
  - Add public key to VPS: `ssh-copy-id user@your-vps-ip`
  - Copy private key content to GitHub secret

#### Optional Secrets:

- **`VPS_PORT`**: SSH port (default: 22)
- **`VPS_DEPLOY_PATH`**: Path on VPS where project is located (default: `~/web-porto`)

### 2. VPS Setup

#### Initial Setup on VPS:

```bash
# Install Docker and Docker Compose
sudo apt update
sudo apt install docker.io docker-compose-plugin -y
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, to avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Create project directory
mkdir -p ~/web-porto
cd ~/web-porto

# Copy necessary files from your local machine:
# - docker-compose.prod.yml
# - nginx.conf
```

#### Copy files to VPS (Optional - GitHub Actions will do this automatically):

The GitHub Actions workflow will automatically copy `docker-compose.prod.yml` and `nginx.conf` to your VPS on each deployment. However, for the first setup, you can manually copy them:

```bash
# From your local machine
scp docker-compose.prod.yml nginx.conf user@your-vps-ip:~/web-porto/
```

### 3. GitHub Container Registry Setup

The workflow automatically uses GitHub Container Registry (ghcr.io). No additional setup needed - it uses `GITHUB_TOKEN` automatically.

**Note**: If your repository is private, you may need to make the package public or configure access:

1. Go to your repository → Packages
2. Click on your package
3. Package settings → Change visibility (if needed)

### 4. First Deployment

1. Push your code to the `main` or `master` branch
2. GitHub Actions will automatically:
   - Build the Docker image
   - Push to GitHub Container Registry
   - Copy `docker-compose.prod.yml` and `nginx.conf` to your VPS
   - Pull the latest image on your VPS
   - Deploy/restart the container

Or trigger manually:

- Go to Actions tab → Build and Deploy → Run workflow

**Note**: The workflow will automatically copy the necessary files to your VPS, so you don't need to manually copy them after the first setup.

### 5. Verify Deployment

After deployment, check:

- Container is running: `docker ps`
- View logs: `docker logs web-porto`
- Access your site: `http://your-vps-ip`

## Workflow Files

- **`.github/workflows/deploy.yml`**: Builds and deploys on push to main/master
- **`.github/workflows/ci.yml`**: Runs tests and builds on PRs

## Manual Deployment (Alternative)

If you prefer to deploy manually:

```bash
# On your VPS
cd ~/web-porto
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## Troubleshooting

### SSH Connection Issues

- Verify SSH key is correctly added to GitHub secrets
- Test SSH connection: `ssh -i ~/.ssh/your-key user@vps-ip`
- Check VPS firewall allows SSH (port 22)

### Docker Login Issues

- Ensure `GITHUB_TOKEN` has package write permissions
- Check package visibility settings in GitHub

### Container Not Starting

- Check logs: `docker logs web-porto`
- Verify nginx.conf exists in deployment path
- Check port 80 is not in use: `sudo netstat -tulpn | grep :80`

## Security Notes

- Keep your SSH keys secure
- Use strong passwords
- Consider setting up SSL/TLS with Let's Encrypt
- Regularly update Docker images
- Monitor container logs for issues
