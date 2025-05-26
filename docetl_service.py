from flask import Flask, request, jsonify
import easyocr
import os
import json
import requests

app = Flask(__name__)
reader = easyocr.Reader(['en'])

OCR_RESULTS_DIR = './ocr_results'  # Where to save JSON files
ANYTHINGLLM_ENDPOINT = 'http://ollama:3001/api/document'  # Update as needed

os.makedirs(OCR_RESULTS_DIR, exist_ok=True)

@app.route('/process', methods=['POST'])
def process_document():
    data = request.json
    file_path = data.get('path')
    original_name = data.get('originalName')

    if not file_path or not os.path.exists(file_path):
        return jsonify({'error': 'File not found'}), 400

    # Step 1: Run OCR
    print(f"[OCR] Processing {file_path} ...")
    results = reader.readtext(file_path, detail=0)
    extracted_text = '\n'.join(results)

    # Step 2: Save JSON
    json_path = os.path.join(OCR_RESULTS_DIR, f"{os.path.splitext(original_name)[0]}.json")
    with open(json_path, 'w') as f:
        json.dump({'text': extracted_text, 'file': original_name}, f)
    print(f"[OCR] Saved results to {json_path}")

    # Step 3: Send to AnythingLLM (optional)
    try:
        response = requests.post(ANYTHINGLLM_ENDPOINT, json={
            'filename': original_name,
            'content': extracted_text
        })
        response.raise_for_status()
        print(f"[LLM] Sent {original_name} to AnythingLLM")
    except Exception as e:
        print(f"[LLM] Failed to send to AnythingLLM: {e}")

    return jsonify({'message': 'Processed successfully'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
