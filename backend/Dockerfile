# 1. Base Image: Use Python 3.9 (Small & Stable)
FROM python:3.9-slim

# 2. Settings: Don't write junk files (.pyc), and show logs immediately
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 3. Create the 'app' folder inside the container
WORKDIR /app

# 4. Install System Tools (The Heavy Lifting)
# We need 'build-essential' and 'cmake' to compile the AI library (llama-cpp)
# We need 'libgl1' for PDF/Image processing libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 5. Copy requirements first
# (This caches the installation so future builds are faster)
# 5. Copy requirements
COPY requirements.txt .

# 6. Install Standard Libraries
RUN pip install --no-cache-dir -r requirements.txt

# 7. FORCE INSTALL PRE-BUILT LLAMA-CPP (The Fix)
# This command tells pip: "Only look at this specific URL for the wheel"
RUN pip install llama-cpp-python \
    --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu \
    --prefer-binary \
    --no-cache-dir
    
# 7. Copy your actual code
COPY . .

# 8. Create the models directory (It will be empty for now)
RUN mkdir -p /app/models

# 9. Open the door (Port 8000)
EXPOSE 8000

# 10. Run the Server
CMD ["uvicorn", "api_server:app", "--host", "0.0.0.0", "--port", "8000"]