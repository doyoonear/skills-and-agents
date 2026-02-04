---
name: deploy-with-cloudflare
description: |
  Deploy web applications to Cloudflare Workers and Pages. Specialized in TanStack Start (React SSR), Next.js, Vite, Astro, SvelteKit, and Remix deployments.
  Use when user requests: "Cloudflare에 배포", "Cloudflare Workers 설정", "TanStack Start 배포", "Cloudflare Pages 배포", "배포 후 404 에러", "Wrangler 설정", "deploy to Cloudflare", "Cloudflare deployment", "Workers deployment", "SSR Cloudflare"
  Handles SSR applications (Workers) and static sites (Pages). Troubleshoots 404 errors, build configuration issues, and Node.js compatibility problems.
---

# Deploy with Cloudflare

Deploy web applications to Cloudflare Workers and Pages, with specialized support for TanStack Start (React SSR) deployments.

## Supported Stacks

### 1. TanStack Start (React SSR Framework)
- SSR environment configuration
- Server entry setup
- Vite plugin integration

### 2. Next.js (App Router, Pages Router)
- @cloudflare/next-on-pages setup
- Edge Runtime optimization

### 3. Vite + React (SPA)
- Static site deployment
- Cloudflare Pages configuration

### 4. Other Frameworks
- Astro
- SvelteKit
- Remix

## Deployment Types

- **Cloudflare Workers**: SSR applications, API servers
- **Cloudflare Pages**: Static sites, JAMstack

## TanStack Start Deployment (SSR)

### Required Packages

```json
{
  "devDependencies": {
    "@cloudflare/vite-plugin": "^1.22.1",
    "wrangler": "^4.61.1"
  }
}
```

### wrangler.jsonc Configuration

```jsonc
{
  "$schema": "https://developers.cloudflare.com/workers/wrangler/configuration/",
  "name": "your-app-name",
  "compatibility_date": "2025-02-01",
  "compatibility_flags": ["nodejs_compat"],
  "main": "@tanstack/react-start/server-entry"
}
```

**Critical Points**:
- `main`: Must use `"@tanstack/react-start/server-entry"` (not a physical file path)
- Using physical path like `.output/server/index.mjs` causes 404 errors
- `compatibility_flags` must include `"nodejs_compat"`

### vite.config.ts Configuration

```typescript
import { defineConfig } from 'vite'
import { cloudflare } from '@cloudflare/vite-plugin'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    // Order matters: cloudflare → tanstackStart → viteReact
    cloudflare({
      viteEnvironment: { name: 'ssr' },
    }),
    tanstackStart(),
    viteReact(),
  ],
})
```

**Critical Points**:
- `cloudflare()` plugin requires `viteEnvironment: { name: 'ssr' }` option
- Plugin order is important

### package.json Scripts

```json
{
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "deploy": "pnpm build && wrangler deploy --config dist/server/wrangler.json"
  }
}
```

**Critical Points**:
- Deploy uses `dist/server/wrangler.json` (auto-generated during build)
- NOT `dist/client/wrangler.json`!

## Next.js Deployment (SSR)

### Required Packages

```json
{
  "devDependencies": {
    "@cloudflare/next-on-pages": "^1.13.0",
    "wrangler": "^4.61.1"
  }
}
```

### next.config.js Configuration

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Cloudflare Pages requires Edge Runtime
  experimental: {
    runtime: 'edge',
  },
}

module.exports = nextConfig
```

### Deployment Scripts

```json
{
  "scripts": {
    "pages:build": "npx @cloudflare/next-on-pages",
    "pages:deploy": "pnpm pages:build && wrangler pages deploy .vercel/output/static"
  }
}
```

## Static Site Deployment

### Vite (SPA)

```json
{
  "scripts": {
    "build": "vite build",
    "deploy": "pnpm build && wrangler pages deploy dist"
  }
}
```

### wrangler.toml (Optional)

```toml
name = "my-static-site"
compatibility_date = "2025-02-01"

[site]
bucket = "./dist"
```

## Troubleshooting Guide

### 404 Error After Deployment

**Symptoms**: All pages return 404 errors

**Causes**:
1. Incorrect `main` field in `wrangler.jsonc`
2. Worker code not deployed

**Solution**:
```jsonc
{
  // ❌ Wrong
  "main": ".output/server/index.mjs"

  // ✅ Correct (TanStack Start)
  "main": "@tanstack/react-start/server-entry"
}
```

### Node.js Module Errors

**Symptoms**: `Error: Cannot find module 'node:async_hooks'`

**Solution**: Add `nodejs_compat` to `compatibility_flags`
```jsonc
{
  "compatibility_flags": ["nodejs_compat"]
}
```

### Build Config File Not Found

**Symptoms**: `Could not read file: dist/client/wrangler.json`

**Cause**: Wrong config file path

**Solution**: Use `dist/server/wrangler.json`
```json
{
  "deploy": "pnpm build && wrangler deploy --config dist/server/wrangler.json"
}
```

### Cloudflare Plugin Error

**Symptoms**: `The provided Wrangler config main field doesn't point to an existing file`

**Solution**: Add option to Cloudflare plugin in `vite.config.ts`
```typescript
cloudflare({
  viteEnvironment: { name: 'ssr' },
})
```

## Deployment Workflow

### 1. Initial Setup

```bash
# 1. Login to Cloudflare
npx wrangler login

# 2. Verify login
npx wrangler whoami
```

### 2. Project Configuration

```bash
# Install required packages
pnpm add -D @cloudflare/vite-plugin wrangler

# Create wrangler.jsonc
# Modify vite.config.ts
# Add deploy script to package.json
```

### 3. Deploy

```bash
# Build and deploy
pnpm run deploy

# Or run separately
pnpm build
npx wrangler deploy --config dist/server/wrangler.json
```

### 4. Environment Variables

**Development** (`.dev.vars`):
```env
API_KEY=dev_key
DATABASE_URL=http://localhost:5432
```

**Production**:
```bash
# Set via CLI
npx wrangler secret put API_KEY

# Or via Cloudflare Dashboard
# Workers & Pages > Project > Settings > Environment Variables
```

## Best Practices

### 1. Git Ignore Configuration

```gitignore
# Cloudflare
.dev.vars
dist/
.wrangler/
wrangler.toml
```

### 2. Version Control

- `wrangler.jsonc`: Include in Git (template)
- `.dev.vars`: Exclude from Git (local env vars)
- `dist/`: Exclude from Git (build output)

### 3. Environment Separation

Separate production and staging environments:

```jsonc
{
  "name": "my-app",
  "env": {
    "staging": {
      "name": "my-app-staging"
    },
    "production": {
      "name": "my-app"
    }
  }
}
```

Deploy:
```bash
# Staging
wrangler deploy --env staging

# Production
wrangler deploy --env production
```

## Important Notes

### TanStack Start Specifics

1. **Required Version**: `@tanstack/react-start` v1.138.0 or higher
2. **Server Entry**: Must use `@tanstack/react-start/server-entry`
3. **Plugin Order**: `cloudflare()` → `tanstackStart()` → `viteReact()`
4. **Build Output**: `dist/server/wrangler.json` auto-generated

### Cloudflare Platform Features

1. **Workers vs Pages**:
   - Workers: SSR apps, API servers (direct code deployment)
   - Pages: Static sites + Functions (Git integration)

2. **Limitations**:
   - Free tier: 100,000 requests/day
   - Bundle size: 1MB (after gzip)
   - CPU time: 10ms (Free), 50ms (Paid)

3. **Performance Optimization**:
   - Runs on edge network (distributed globally)
   - Minimal cold starts
   - Automatic scaling

## References

- [TanStack Start Hosting Guide](https://tanstack.com/start/latest/docs/framework/react/guide/hosting)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Cloudflare Vite Plugin](https://developers.cloudflare.com/workers/vite-plugin/)
- [TanStack Start + Cloudflare Example](https://github.com/TanStack/router/tree/main/examples/react/start-basic-cloudflare)

## Pre-Deployment Checklist

- [ ] `@cloudflare/vite-plugin` installed
- [ ] `wrangler` installed
- [ ] `wrangler.jsonc` configured
  - [ ] `main` field correctly set
  - [ ] `nodejs_compat` flag added
- [ ] `vite.config.ts` Cloudflare plugin configured
  - [ ] `viteEnvironment: { name: 'ssr' }` option added
- [ ] `package.json` deploy script added
- [ ] Cloudflare login complete (`wrangler login`)
- [ ] Local build tested (`pnpm build`)
- [ ] Environment variables configured (if needed)
