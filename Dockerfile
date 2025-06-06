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
      corepack prepare pnpm@8.15.9 --activate && pnpm install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then \
      npm ci; \
    elif [ -f yarn.lock ]; then \
      corepack enable yarn && yarn install --frozen-lockfile; \
    elif [ -f package.json ]; then \
      npm install; \
    else \
      echo "No package.json found, skipping install"; \
    fi

# Ensure node_modules exists even when no dependencies are installed
RUN mkdir -p node_modules

# Builder stage
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Ensure required directories exist to prevent COPY errors
RUN mkdir -p public .next/standalone .next/static

# Build only when a Node project is present
RUN if [ -f pnpm-lock.yaml ]; then \
      corepack prepare pnpm@8.15.9 --activate && pnpm run build; \
    elif [ -f package-lock.json ]; then \
      npm run build; \
    elif [ -f yarn.lock ]; then \
      corepack enable yarn && yarn build; \
    elif [ -f package.json ]; then \
      npm run build; \
    else \
      echo "No package.json found, skipping build"; \
    fi

# Production stage
FROM base AS runner
RUN corepack prepare pnpm@8.15.9 --activate
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
