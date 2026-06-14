# Build Python runtime
FROM python:3.10-slim
WORKDIR /app

# Install system dependencies for OpenCV, InsightFace, and patchelf
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libglib2.0-0 \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip install --no-cache-dir numpy==1.24.3 pillow onnxruntime==1.16.3 opencv-python-headless insightface==0.7.3 fastapi uvicorn python-multipart

# Clear executable stack flag from onnxruntime to prevent load failure on some VPS kernels (execstack error)
RUN patchelf --clear-execstack /usr/local/lib/python3.10/site-packages/onnxruntime/capi/onnxruntime_pybind11_state.cpython-310-x86_64-linux-gnu.so

# Pre-download InsightFace buffalo_l model to prevent runtime download delays/failures on VPS
RUN python -c "from insightface.app import FaceAnalysis; FaceAnalysis(name='buffalo_l').prepare(ctx_id=-1)"

# Copy precompiled Go binaries (compiled locally on Windows for Linux target)
COPY gateway .
COPY auth .
COPY attendance .
COPY payroll .
RUN chmod +x gateway auth attendance payroll
COPY process_face.py process_face_api.py ./
COPY service-account.json* ./

# Copy environment files
COPY .env* ./

# Create directory for uploads
RUN mkdir -p uploads/profiles uploads/attendance

EXPOSE 8080 8081 8082 8083
