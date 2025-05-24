#!/bin/bash
set -e

echo "🚀 Setting up Document Intelligence Platform..."

# Create directory structure
mkdir -p {documents,organized,shared,processed,configs,workflows,static,jsoncrack}

# Create simplified package.json
cat > package.json << 'EOF'
{
  "name": "file-organizer",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "multer": "^1.4.5",
    "fs-extra": "^11.1.0"
  }
}
EOF

# Create Python requirements
cat > requirements.txt << 'EOF'
flask==2.3.3
pandas==2.0.3
PyPDF2==3.0.1
pillow==10.0.0
requests==2.31.0
EOF

# Create simple file organizer service
cat > organizer.js << 'EOF'
const express = require('express');
const multer = require('multer');
const fs = require('fs-extra');
const path = require('path');

const app = express();
const upload = multer({ dest: '/workspace/documents/' });

app.use(express.json());
app.use(express.static('public'));

app.get('/', (req, res) => {
  res.json({ status: 'File Organizer running', version: '1.0.0' });
});

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    const fileType = path.extname(file.originalname).toLowerCase();
    const organizedPath = `/workspace/organized/${fileType.slice(1) || 'unknown'}`;
    
    await fs.ensureDir(organizedPath);
    const newPath = path.join(organizedPath, file.originalname);
    await fs.move(file.path, newPath);
    
    res.json({ 
      message: 'File organized successfully',
      path: newPath,
      type: fileType
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/files', async (req, res) => {
  try {
    const organized = await fs.readdir('/workspace/organized');
    const fileTree = {};
    
    for (const type of organized) {
      try {
        const files = await fs.readdir(`/workspace/organized/${type}`);
        fileTree[type] = files;
      } catch (e) {
        fileTree[type] = [];
      }
    }
    
    res.json(fileTree);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`File Organizer running on port ${PORT}`);
});
EOF

# Create simple DocETL service
cat > docetl_service.py << 'EOF'
from flask import Flask, request, jsonify
import os
import json
from datetime import datetime
try:
    import PyPDF2
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False

app = Flask(__name__)

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy", 
        "service": "DocETL",
        "pdf_support": PDF_AVAILABLE
    })

@app.route('/process', methods=['POST'])
def process_document():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
        
        # Simple text processing
        content = file.read()
        result = {
            "filename": file.filename,
            "size": len(content),
            "processed_at": datetime.now().isoformat(),
            "status": "processed"
        }
        
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

# Create simple nginx config
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        
        location /ai/ {
            proxy_pass http://host.docker.internal:3001/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /workflows/ {
            proxy_pass http://host.docker.internal:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /files/ {
            proxy_pass http://host.docker.internal:3002/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /process/ {
            proxy_pass http://host.docker.internal:5000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

# Create main dashboard
cat > static/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document Intelligence Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; color: white; margin-bottom: 3rem; }
        .header h1 { font-size: 3rem; margin-bottom: 1rem; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header p { font-size: 1.2rem; opacity: 0.9; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 2rem; }
        .card { background: rgba(255,255,255,0.95); border-radius: 15px; padding: 2rem; box-shadow: 0 8px 32px rgba(0,0,0,0.1); backdrop-filter: blur(10px); transition: transform 0.3s ease, box-shadow 0.3s ease; }
        .card:hover { transform: translateY(-5px); box-shadow: 0 12px 40px rgba(0,0,0,0.15); }
        .card h3 { color: #2c3e50; margin-bottom: 1rem; font-size: 1.5rem; display: flex; align-items: center; gap: 0.5rem; }
        .card p { color: #666; margin-bottom: 1.5rem; line-height: 1.6; }
        .btn { display: inline-block; background: linear-gradient(45deg, #3498db, #2980b9); color: white; padding: 12px 24px; text-decoration: none; border-radius: 25px; transition: all 0.3s ease; font-weight: 600; }
        .btn:hover { background: linear-gradient(45deg, #2980b9, #1f5582); transform: scale(1.05); }
        .status { margin-top: 1rem; padding: 0.75rem; border-radius: 8px; font-weight: 500; }
        .status.online { background: rgba(46, 204, 113, 0.1); color: #27ae60; border: 1px solid rgba(46, 204, 113, 0.3); }
        .status.offline { background: rgba(231, 76, 60, 0.1); color: #e74c3c; border: 1px solid rgba(231, 76, 60, 0.3); }
        .status.checking { background: rgba(241, 196, 15, 0.1); color: #f39c12; border: 1px solid rgba(241, 196, 15, 0.3); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Document Intelligence Platform</h1>
            <p>Process documents, extract insights, and automate workflows with AI</p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>🤖 AI Document Chat</h3>
                <p>Upload documents and chat with them using local AI models. Extract insights, ask questions, and get intelligent responses.</p>
                <a href="/ai/" class="btn" target="_blank">Open AI Chat</a>
                <div class="status checking" id="ai-status">Checking status...</div>
            </div>
            
            <div class="card">
                <h3>⚙️ Workflow Automation</h3>
                <p>Create and manage automated document processing workflows. Build pipelines for data extraction and analysis.</p>
                <a href="/workflows/" class="btn" target="_blank">Open Workflows</a>
                <div class="status checking" id="workflow-status">Checking status...</div>
            </div>
            
            <div class="card">
                <h3>📁 File Organization</h3>
                <p>Automatically organize and categorize your documents by type, content, and metadata.</p>
                <a href="/files/" class="btn" target="_blank">Organize Files</a>
                <div class="status checking" id="files-status">Checking status...</div>
            </div>
            
            <div class="card">
                <h3>🔍 Document Processing</h3>
                <p>Extract text from PDFs, images, and other documents. Perform OCR and content analysis.</p>
                <a href="/process/" class="btn" target="_blank">Process Documents</a>
                <div class="status checking" id="process-status">Checking status...</div>
            </div>
            
            <div class="card">
                <h3>💾 Data Management</h3>
                <p>Manage processed data, view analytics, and export results in various formats.</p>
                <a href="#" class="btn" onclick="showInfo('Data management features coming soon!')">View Data</a>
                <div class="status online">Ready</div>
            </div>
            
            <div class="card">
                <h3>📊 Analytics Dashboard</h3>
                <p>Monitor document processing metrics, workflow performance, and system health.</p>
                <a href="#" class="btn" onclick="showInfo('Analytics dashboard in development!')">View Analytics</a>
                <div class="status online">Ready</div>
            </div>
        </div>
    </div>
    
    <script>
        function showInfo(message) {
            alert(message);
        }
        
        // Check service status
        async function checkStatus(url, elementId, serviceName) {
            const element = document.getElementById(elementId);
            try {
                const response = await fetch(url, { method: 'GET', timeout: 5000 });
                if (response.ok) {
                    element.textContent = `${serviceName} is online`;
                    element.className = 'status online';
                } else {
                    element.textContent = `${serviceName} is offline`;
                    element.className = 'status offline';
                }
            } catch (error) {
                element.textContent = `${serviceName} is offline`;
                element.className = 'status offline';
            }
        }
        
        // Check all services with a delay to allow startup
        setTimeout(() => {
            checkStatus('https://3001-' + window.location.hostname.split('-').slice(1).join('-'), 'ai-status', 'AI Chat');
            checkStatus('https://8080-' + window.location.hostname.split('-').slice(1).join('-'), 'workflow-status', 'Workflows');
            checkStatus('https://3002-' + window.location.hostname.split('-').slice(1).join('-'), 'files-status', 'File Organizer');
            checkStatus('https://5000-' + window.location.hostname.split('-').slice(1).join('-'), 'process-status', 'Document Processing');
        }, 2000);
    </script>
</body>
</html>
EOF

echo "✅ Setup files created successfully!"
echo "Next: Run './start.sh' to launch the platform"

chmod +x start.sh
EOF

# Create Dockerfiles
cat > Dockerfile.organizer << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY organizer.js .
EXPOSE 3000
CMD ["node", "organizer.js"]
EOF

cat > Dockerfile.docetl << 'EOF'
FROM python:3.9-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY docetl_service.py .
EXPOSE 5000
CMD ["python", "docetl_service.py"]
EOF

chmod +x setup.sh

echo "✅ Platform setup completed!"
