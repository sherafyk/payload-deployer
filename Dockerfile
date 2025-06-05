# Multi-stage build for Payload CMS
# Uses Node 20 on Alpine Linux

# Base stage with Node runtime
FROM node:20-alpine AS base

# Stage for installing dependencies
FROM base AS deps
# libc6-compat is often required for Next.js
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies using the available lockfile
COPY package.json pnpm-lock.yaml* package-lock.json* yarn.lock* ./
RUN \
  if [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm install --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  else echo "No lockfile found" && exit 1; fi

# Builder stage
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build without requiring DB connection
RUN corepack enable pnpm && pnpm exec next build --experimental-build-mode compile

# Production stage
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs

COPY --from=builder /app/public ./public
RUN mkdir .next && chown nextjs:nodejs .next
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000
CMD ["node", "server.js"]
