# =========================================================
# Stage 1: Build custom n8n node
# =========================================================
FROM node:24-alpine3.22 AS builder

WORKDIR /build

# Native build dependencies for isolated-vm
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    gcc \
    libc-dev \
    linux-headers

# Install n8n-workflow
RUN mkdir -p /build/node_modules && \
    cd /build && \
    npm install n8n-workflow

# Copy custom node
COPY . /build/node_modules/n8n-nodes-puppeteer

# Install dependencies and build
RUN cd /build/node_modules/n8n-nodes-puppeteer && \
    npm install --include=dev && \
    npm run build


# =========================================================
# Stage 2: n8n runtime
# =========================================================
FROM n8nio/n8n:latest

USER root

# ---------------------------------------------------------
# Bootstrap apk
# Docker Hardened Images/Alpine không có apk sẵn
# ---------------------------------------------------------
RUN ARCH=$(uname -m) && \
    APK_URL="https://dl-cdn.alpinelinux.org/alpine/v3.24/main/${ARCH}/" && \
    APK_FILE=$(wget -qO- "$APK_URL" \
        | grep -o 'href="apk-tools-static-[^"]*\.apk"' \
        | head -1 \
        | cut -d'"' -f2) && \
    echo "Downloading apk-tools: ${APK_FILE}" && \
    wget -q "${APK_URL}${APK_FILE}" \
        -O /tmp/apk-tools-static.apk && \
    mkdir -p /tmp/apk-tools && \
    tar -xzf /tmp/apk-tools-static.apk \
        -C /tmp/apk-tools && \
    /tmp/apk-tools/sbin/apk.static \
        -X https://dl-cdn.alpinelinux.org/alpine/v3.24/main \
        -U \
        --allow-untrusted \
        add apk-tools && \
    rm -rf \
        /tmp/apk-tools \
        /tmp/apk-tools-static.apk


# ---------------------------------------------------------
# Chromium
# ---------------------------------------------------------
RUN apk add --no-cache \
#RUN apk add \
    chromium \
    nss \
    glib \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    udev \
    ttf-liberation \
    font-noto-emoji


# ---------------------------------------------------------
# Puppeteer
# ---------------------------------------------------------
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium


# ---------------------------------------------------------
# Custom nodes
# ---------------------------------------------------------
RUN mkdir -p /opt/n8n-custom-nodes/node_modules

COPY --from=builder \
    /build/node_modules/n8n-workflow \
    /opt/n8n-custom-nodes/node_modules/n8n-workflow

COPY --from=builder \
    /build/node_modules/n8n-nodes-puppeteer \
    /opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer


# ---------------------------------------------------------
# Permissions
# ---------------------------------------------------------
RUN chown -R node:node /opt/n8n-custom-nodes


# ---------------------------------------------------------
# Custom entrypoint
# ---------------------------------------------------------
COPY docker/docker-custom-entrypoint.sh \
    /docker-custom-entrypoint.sh

RUN chmod +x /docker-custom-entrypoint.sh && \
    chown node:node /docker-custom-entrypoint.sh


USER node

ENTRYPOINT ["/docker-custom-entrypoint.sh"]
