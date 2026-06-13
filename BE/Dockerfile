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

# Copy precompiled Go binaries (compiled locally on Windows for Linux target)
COPY gateway .
COPY auth .
COPY attendance .
COPY payroll .
COPY process_face.py .
COPY service-account.json* ./

# Copy environment files
COPY .env* ./

# Create directory for uploads
RUN mkdir -p uploads/profiles uploads/attendance

EXPOSE 8080 8081 8082 8083
