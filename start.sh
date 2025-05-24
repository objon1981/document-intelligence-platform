#!/bin/bash

echo "🚀 Starting Document Intelligence Platform..."

# Start Docker daemon if not running
sudo service docker start

# Build and start all services
docker-compose up -d --build

echo "⏳ Waiting for services to initialize..."
sleep 45

# Download AI model
echo "📥 Downloading Llama2 model (this may take a few minutes)..."
docker exec ollama ollama pull llama2:7b-chat

echo "✅ Platform is ready!"
echo ""
echo "🌐 Platform URLs (click to open):"
echo "📊 Main Dashboard: $(gp url 80)"
echo "🤖 AI Chat: $(gp url 3001)"
echo "⚙️ Workflows: $(gp url 8080)"
echo "📄 Document Processing: $(gp url 5000)"
echo ""
gp preview $(gp url 80)
