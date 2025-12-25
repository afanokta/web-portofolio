# Environment Variables Guide

This guide explains how to set and use environment variables in your GitHub Actions workflow and Docker deployment.

## Three Levels of Environment Variables

### 1. Workflow Level (Top of file)
Available to all jobs in the workflow:
```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  NODE_ENV: production
  PUBLIC_API_URL: https://api.example.com
```

### 2. Job Level (Inside a job)
Available to all steps within that job:
```yaml
jobs:
  build-and-deploy:
    env:
      DEPLOY_ENV: production
      BUILD_DATE: ${{ github.event.head_commit.timestamp }}
```

### 3. Step Level (Inside a step)
Only available in that specific step:
```yaml
- name: Build Docker image
  env:
    DOCKER_BUILDKIT: 1
    CUSTOM_VAR: value
```

## Using Secrets as Environment Variables

To use GitHub Secrets in your workflow:

1. **Add secrets in GitHub:**
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add your secret (e.g., `API_KEY`, `DATABASE_URL`)

2. **Use in workflow:**
   ```yaml
   env:
     API_KEY: ${{ secrets.API_KEY }}
     DATABASE_URL: ${{ secrets.DATABASE_URL }}
   ```

3. **Use in steps:**
   ```yaml
   - name: Deploy
     env:
       SECRET_VAR: ${{ secrets.MY_SECRET }}
     run: echo $SECRET_VAR
   ```

## Passing Environment Variables to Docker

### Option 1: Build Arguments (for build-time)
If you need env vars during Docker build:

1. **In Dockerfile:**
   ```dockerfile
   ARG NODE_ENV=production
   ARG PUBLIC_API_URL
   ENV NODE_ENV=$NODE_ENV
   ENV PUBLIC_API_URL=$PUBLIC_API_URL
   ```

2. **In workflow:**
   ```yaml
   - name: Build and push Docker image
     uses: docker/build-push-action@v5
     with:
       build-args: |
         NODE_ENV=production
         PUBLIC_API_URL=${{ secrets.PUBLIC_API_URL }}
   ```

### Option 2: Container Environment Variables (for runtime)
Pass env vars to the running container:

1. **In docker-compose.prod.yml:**
   ```yaml
   services:
     web:
       environment:
         - NODE_ENV=production
         - PUBLIC_API_URL=${PUBLIC_API_URL}
         - API_KEY=${API_KEY}
   ```

2. **In workflow (during deployment):**
   ```yaml
   script: |
     export PUBLIC_API_URL=${{ secrets.PUBLIC_API_URL }}
     export API_KEY=${{ secrets.API_KEY }}
     docker-compose -f docker-compose.prod.yml up -d
   ```

### Option 3: Using .env File (Recommended for many vars)
1. **Create .env file on VPS:**
   ```bash
   # On your VPS
   cd ~/web-porto
   nano .env
   ```
   ```env
   NODE_ENV=production
   PUBLIC_API_URL=https://api.example.com
   API_KEY=your-key-here
   ```

2. **Update docker-compose.prod.yml:**
   ```yaml
   services:
     web:
       env_file:
         - .env
   ```

3. **Or pass secrets from GitHub to .env file:**
   ```yaml
   - name: Create .env file on VPS
     uses: appleboy/ssh-action@v1.0.3
     with:
       script: |
         cat > ~/web-porto/.env << EOF
         NODE_ENV=production
         PUBLIC_API_URL=${{ secrets.PUBLIC_API_URL }}
         API_KEY=${{ secrets.API_KEY }}
         EOF
   ```

## Example: Complete Setup

### 1. Add secrets in GitHub:
- `PUBLIC_API_URL`
- `API_KEY`
- `DATABASE_URL`

### 2. Update deploy.yml:
```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  NODE_ENV: production

jobs:
  build-and-deploy:
    env:
      PUBLIC_API_URL: ${{ secrets.PUBLIC_API_URL }}
    
    steps:
      - name: Deploy to VPS
        script: |
          # Create .env file with secrets
          cat > .env << EOF
          NODE_ENV=production
          PUBLIC_API_URL=${{ secrets.PUBLIC_API_URL }}
          API_KEY=${{ secrets.API_KEY }}
          DATABASE_URL=${{ secrets.DATABASE_URL }}
          EOF
          
          # Copy .env to VPS
          scp .env user@vps:~/web-porto/
          
          # Deploy
          docker-compose -f docker-compose.prod.yml up -d
```

### 3. Update docker-compose.prod.yml:
```yaml
services:
  web:
    env_file:
      - .env
```

## Best Practices

1. **Never commit secrets** - Always use GitHub Secrets
2. **Use .env file** for many environment variables
3. **Use workflow env** for non-sensitive configuration
4. **Use secrets** for sensitive data (API keys, passwords, etc.)
5. **Document your env vars** in this file or README

## Accessing Environment Variables in Astro

If you need to use env vars in your Astro app:

1. **Prefix with `PUBLIC_`** for client-side access:
   ```env
   PUBLIC_API_URL=https://api.example.com
   ```
   Then use: `import.meta.env.PUBLIC_API_URL`

2. **Server-side only** (without PUBLIC_ prefix):
   ```env
   DATABASE_URL=postgres://...
   ```
   Access via: `import.meta.env.DATABASE_URL` (only in server-side code)


