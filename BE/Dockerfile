# Dockerfile
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o gateway cmd/gateway/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o auth cmd/auth/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o attendance cmd/attendance/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o payroll cmd/payroll/main.go

# Build Python runtime
FROM python:3.10-slim
WORKDIR /app

# Install system dependencies for OpenCV and InsightFace compilation
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip install --no-cache-dir numpy==1.24.3 pillow onnxruntime==1.16.3 opencv-python-headless insightface==0.7.3

# Copy compiled Go binaries
COPY --from=builder /app/gateway .
COPY --from=builder /app/auth .
COPY --from=builder /app/attendance .
COPY --from=builder /app/payroll .
COPY --from=builder /app/process_face.py .
COPY --from=builder /app/service-account.json* ./

# Copy environment files
COPY --from=builder /app/.env* ./

# Create directory for uploads
RUN mkdir -p uploads/profiles uploads/attendance

EXPOSE 8080 8081 8082 8083
