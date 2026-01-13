FROM node:22-alpine3.20

# Install security updates
RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies and clean cache
RUN npm ci --omit=dev && \
    npm cache clean --force

# Copy only necessary files
COPY server.js .

# Set proper ownership
RUN chown -R node:node /app

EXPOSE 8001

USER node

# Use unbuffered output for better logging
ENV NODE_ENV=production

CMD ["node", "server.js"]
