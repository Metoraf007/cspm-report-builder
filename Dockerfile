FROM python:3.12-slim

WORKDIR /app

# System deps for Playwright Chromium + Hebrew fonts
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 \
        libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
        libxrandr2 libgbm1 libpango-1.0-0 libcairo2 \
        libasound2t64 libxshmfence1 libxfixes3 libx11-xcb1 \
        fonts-noto fonts-noto-cjk fonts-unifont \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install only the Chromium browser (no system deps)
RUN playwright install chromium

COPY . .

RUN mkdir -p output uploads/states

EXPOSE 8080

# Ensure writable dirs even when host volumes are mounted
CMD ["sh", "-c", "chmod -R 777 /app/output /app/uploads 2>/dev/null; exec gunicorn --bind 0.0.0.0:8080 --workers 2 --timeout 120 app:app"]
