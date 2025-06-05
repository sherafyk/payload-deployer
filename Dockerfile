# Multi-stage build for Payload CMS
# Uses Node 20 on Alpine Linux

# Base stage with Node runtime
FROM node:20-alpine AS base

# Stage for installing dependencies
FROM base AS deps
# libc6-compat is often required for Next.js
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies when a Node project is present
COPY package.json* pnpm-lock.yaml* package-lock.json* yarn.lock* ./
RUN \
  if [ -f pnpm-lock.yaml ]; then \
    corepack enable pnpm && pnpm install --frozen-lockfile; \
  elif [ -f package-lock.json ]; then \
    npm ci; \
  elif [ -f yarn.lock ]; then \
    yarn --frozen-lockfile; \
  elif [ -f package.json ]; then \
    npm install; \
  else \
    echo "No package.json found, skipping install"; \
  fi

# Builder stage
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Ensure required directories exist to prevent COPY errors
RUN mkdir -p public .next/standalone .next/static

# Build only when a Node project is present
RUN if [ -f package.json ]; then \
      corepack enable pnpm && pnpm exec next build --experimental-build-mode compile; \
    else \
      echo "No package.json found, skipping build"; \
    fi

# Production stage
FROM base AS runner
RUN corepack enable pnpm
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs

COPY --from=builder /app/public ./public
RUN mkdir -p .next .next/static && chown nextjs:nodejs .next
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000
CMD ["node", "server.js"]
