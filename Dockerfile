# Stage 1: Build frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
COPY app/frontend/package.json app/frontend/package-lock.json* app/frontend/pnpm-lock.yaml* ./
RUN npm install --legacy-peer-deps
COPY app/frontend/ ./
ENV VITE_API_URL=""
RUN npx vite build

# Stage 2: Python backend + static frontend
FROM python:3.11-slim AS backend
WORKDIR /app
ENV PYTHONPATH=/app

RUN pip install --no-cache-dir poetry==1.7.1
COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

COPY src/ ./src/
COPY v2/ ./v2/
COPY app/ ./app/

# Copy built frontend into static directory
COPY --from=frontend-builder /frontend/dist /app/static

RUN groupadd -g 1000 hedgefund && useradd -u 1000 -g 1000 -s /bin/false hedgefund \
    && mkdir -p /app/data && chown -R 1000:1000 /app/data
USER 1000:1000

EXPOSE 8501
CMD ["python", "-m", "uvicorn", "app.backend.main:app", "--host", "0.0.0.0", "--port", "8501"]
