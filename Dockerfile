# Stage 1: Build & Dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirement.txt .
RUN pip install --upgrade pip --no-cache-dir && \
    pip install --user --no-cache-dir -r requirement.txt

# Stage 2: Final Production Stage (Hardened Non-Root Container)
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    default-libmysqlclient-dev \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Create Non-Root System User for Container Security Hardening
RUN groupadd -r appgroup && useradd -r -g appgroup -u 10001 appuser

COPY --from=builder /root/.local /home/appuser/.local
COPY . .

# Adjust permissions
RUN chown -R appuser:appgroup /app

USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

# Healthcheck for Application Tier
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Production Gunicorn Entrypoint with worker threads
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "3", "--threads", "2", "app:app"]