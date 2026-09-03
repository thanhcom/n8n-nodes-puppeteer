FROM n8nio/n8n:latest

USER root

# Cài đặt trực tiếp python3, make, g++ và các dependencies cho Chromium
RUN apk add --no-cache \
	python3 \
	make \
	g++ \
	chromium \
	nss \
	glib \
	freetype \
	freetype-dev \
	harfbuzz \
	ca-certificates \
	ttf-freefont \
	udev \
	ttf-liberation \
	font-noto-emoji

# Tell Puppeteer to use installed Chrome instead of downloading it
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
	PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install n8n-nodes-puppeteer in a permanent location
RUN mkdir -p /opt/n8n-custom-nodes && \
	cd /opt/n8n-custom-nodes && \
	npm install n8n-workflow
COPY . /opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer
RUN cd /opt/n8n-custom-nodes/node_modules/n8n-nodes-puppeteer && \
	npm install --include=dev && \
	npm run build && \
	chown -R node:node /opt/n8n-custom-nodes

# Copy our custom entrypoint
COPY docker/docker-custom-entrypoint.sh /docker-custom-entrypoint.sh
RUN chmod +x /docker-custom-entrypoint.sh && \
	chown node:node /docker-custom-entrypoint.sh

USER node

ENTRYPOINT ["/docker-custom-entrypoint.sh"]
