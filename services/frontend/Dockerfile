# Build stage
FROM node:22-alpine3.20 AS builder

# Install security updates
RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev && \
    npm install && \
    npm cache clean --force

COPY . .
RUN npm run build

# Production stage
FROM nginx:1.27-alpine3.20

# Install security updates and create nginx user
RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/* && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Copy built files
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

# Use unprivileged user
USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
