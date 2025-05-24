#!/bin/bash
set -e

echo "🚀 Setting up Document Intelligence Platform for Gitpod..."

# Create directory structure
mkdir -p {documents,organized,shared,processed,configs,workflows,static,jsoncrack}

# Create Dockerfile for file organizer
cat << 'EOF' > Dockerfile.organizer
FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache python3 py3-pip poppler-utils tesseract-ocr
COPY package.json .
RUN npm install
COPY organizer.js .
EXPOSE 3000
CMD ["node", "organizer.js"]
EOF

# Create Dockerfile for DocETL
cat << 'EOF' > Dockerfile.docetl
FROM python:3.9-slim
WORKDIR /app
RUN apt-get update && apt-get install -y \
    poppler-utils tesseract-ocr libtesseract-dev \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY docetl_service.py .
EXPOSE 5000
CMD ["python", "docetl_service.py"]
EOF

# Create package.json
cat << 'EOF' > package.json
{
  "name": "file-organizer",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "multer": "^1.4.5",
    "pdf-parse": "^1.1.1",
    "node-tesseract-ocr": "^2.2.1",
    "fs-extra": "^11.1.0"
  }
}
EOF

# Create requirements.txt
cat << 'EOF' > requirements.txt
flask==2.3.3
pandas==2.0.3
numpy==1.24.3
pytesseract==0.3.10
PyPDF2==3.0.1
python-docx==0.8.11
openpyxl==3.1.2
pillow==10.0.0
requests==2.31.0
beautifulsoup4==4.12.2
EOF

# Create service files (organizer.js, docetl_service.py, nginx.conf, etc.)
# ... (files from previous artifacts)

echo "✅ Setup completed!"
