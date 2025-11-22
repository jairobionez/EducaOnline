# Multi-stage Dockerfile for Angular app (Nx workspace)
# Stage 1: build
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
COPY ./tsconfig.base.json ./
COPY ./nx.json ./
COPY ./apps/educa-online ./apps/educa-online
COPY ./libs ./libs

RUN npm ci --silent

# Build the app (adjust the nx command if your project name differs)
RUN npx nx build educa-online --configuration=production

# Stage 2: serve with nginx
FROM nginx:alpine
# Nx produces a `browser` folder for the client build; copy that into nginx html root
COPY --from=builder /app/dist/apps/educa-online/browser/. /usr/share/nginx/html/

# Expose default http port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
