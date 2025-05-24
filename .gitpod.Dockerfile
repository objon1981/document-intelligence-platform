FROM gitpod/workspace-full:latest

# Install Docker Compose
RUN sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
RUN sudo apt-get update && \
    sudo apt-get install -y \
    poppler-utils \
    tesseract-ocr \
    nginx \
    && sudo apt-get clean

# Pre-pull some Docker images to speed up startup
RUN docker pull ollama/ollama:latest || true
RUN docker pull mintplexlabs/anythingllm:latest || true
RUN docker pull nginx:alpine || true
RUN docker pull postgres:15-alpine || true
RUN docker pull redis:7-alpine || true
