#!/bin/bash

echo "🚀 Starting Document Intelligence Platform..."

# Ensure Docker is running
sudo service docker start

echo "📦 Starting core services..."

# Start Ollama first
docker run -d \
  --name ollama \
  -p 11434:11434 \
  -v ollama_data:/root/.ollama \
  ollama/ollama:latest

# Start AnythingLLM
docker run -d \
  --name anythingllm \
  -p 3001:3001 \
  -v anythingllm_storage:/app/server/storage \
  -e LLM_PROVIDER=ollama \
  -e OLLAMA_BASE_PATH=http://host.docker.internal:11434 \
  mintplexlabs/anythingllm:latest

# Start Kestra
docker run -d \
  --name kestra \
  -p 8080:8080 \
  -v kestra_data:/app/storage \
  kestra/kestra:latest

echo "🏗️ Building custom services..."

# Build and start file organizer
docker build -f Dockerfile.organizer -t file-organizer .
docker run -d \
  --name file-organizer \
  -p 3002:3000 \
  -v $(pwd)/documents:/workspace/documents \
  -v $(pwd)/organized:/workspace/organized \
  file-organizer

# Build and start DocETL
docker build -f Dockerfile.docetl -t docetl .
docker run -d \
  --name docetl \
  -p 5000:5000 \
  -v $(pwd)/documents:/workspace/input \
  -v $(pwd)/processed:/workspace/output \
  docetl

# Start nginx
docker run -d \
  --name nginx-proxy \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf \
  -v $(pwd)/static:/usr/share/nginx/html \
  nginx:alpine

echo "⏳ Waiting for services to start..."
sleep 30

echo "📥 Downloading AI model..."
docker exec ollama ollama pull llama2:7b-chat-q4_0 &

echo "✅ Platform is starting up!"
echo ""
echo "🌐 Service URLs:"
echo "📊 Dashboard: $(gp url 80)"
echo "🤖 AI Chat: $(gp url 3001)"
echo "⚙️ Workflows: $(gp url 8080)"
echo "📁 Files: $(gp url 3002)"
echo "🔍 Processing: $(gp url 5000)"
echo ""
echo "Opening main dashboard..."
gp preview $(gp url 80)

# Show status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
