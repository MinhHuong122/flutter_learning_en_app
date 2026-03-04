# DeepSeek OCR Integration Guide

## Overview
This guide explains how to integrate DeepSeek-OCR backend with the Flutter app for automatic vocabulary extraction from images.

**Latest Update:** Using DeepSeek-OCR (January 2026 version)

## Architecture

```
Flutter App (Mobile)
    ↓ (Upload Image)
Python Backend (Server) - FastAPI
    ↓ (Process with DeepSeek OCR)
DeepSeek-OCR Model (vLLM or Transformers)
    ↓ (Extract Text)
English Dictionary Matching
    ↓ (Return Vocabulary with Meanings)
Flutter App (Display Flashcards)
```

## Prerequisites

### Hardware Requirements
- **GPU**: NVIDIA GPU with at least 16GB VRAM (recommended: A100, H100, or RTX 4090)
- **CUDA**: Version 11.8 or later
- **RAM**: At least 32GB system RAM
- **Storage**: 50GB+ for model and dependencies

### Software Requirements
- Python 3.12.9
- CUDA 11.8 or later
- pip package manager

## Setup Python Backend

### 1. Clone DeepSeek-OCR Repository

```bash
git clone https://github.com/deepseek-ai/DeepSeek-OCR.git
cd DeepSeek-OCR
```

### 2. Create Virtual Environment

```bash
conda create -n deepseek-ocr python=3.12.9 -y
conda activate deepseek-ocr
```

### 3. Install Dependencies

```bash
# Download vLLM wheel (see DeepSeek-OCR repo for latest link)
# Install PyTorch with CUDA support
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu118

# Install vLLM (download .whl from repo)
pip install vllm-0.8.5+cu118-cp38-abi3-manylinux1_x86_64.whl

# Install other requirements
pip install -r requirements.txt
pip install flash-attn==2.7.3 --no-build-isolation

# Install FastAPI for web server
pip install fastapi uvicorn python-multipart pillow
```

### 4. Create Backend API Server

Create `backend_ocr_api.py`:

```python
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from vllm import LLM, SamplingParams
from vllm.model_executor.models.deepseek_ocr import NGramPerReqLogitsProcessor
from PIL import Image
import io
import os
import re
import tempfile

app = FastAPI(title="DeepSeek OCR API")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load DeepSeek OCR model with vLLM
print("Loading DeepSeek-OCR model...")
llm = LLM(
    model="deepseek-ai/DeepSeek-OCR",
    enable_prefix_caching=False,
    mm_processor_cache_gb=0,
    logits_processors=[NGramPerReqLogitsProcessor]
)
print("Model loaded successfully!")

@app.post("/api/ocr/extract")
async def extract_vocabulary(image: UploadFile = File(...)):
    """
    Extract vocabulary from uploaded image using DeepSeek OCR
    """
    try:
        print(f"Receiving image: {image.filename}")
        
        # Read and save image temporarily
        contents = await image.read()
        img = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # Save to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.png') as tmp:
            img.save(tmp.name)
            temp_path = tmp.name
        
        print(f"Processing image: {temp_path}")
        
        # OCR prompt optimized for vocabulary extraction
        prompt = "<image>\\nExtract all English vocabulary words from this image. List them clearly."
        
        # Prepare input for vLLM
        model_input = [{
            "prompt": prompt,
            "multi_modal_data": {"image": img}
        }]
        
        # Sampling parameters
        sampling_param = SamplingParams(
            temperature=0.0,
            max_tokens=8192,
            extra_args=dict(
                ngram_size=30,
                window_size=90,
                whitelist_token_ids={128821, 128822},
            ),
            skip_special_tokens=False,
        )
        
        # Generate OCR output
        model_outputs = llm.generate(model_input, sampling_param)
        extracted_text = model_outputs[0].outputs[0].text
        
        print(f"Extracted text: {extracted_text[:200]}...")
        
        # Extract individual words
        words = extract_words_from_text(extracted_text)
        
        # Clean up
        os.remove(temp_path)
        
        return {
            "extracted_text": extracted_text,
            "words": words,
            "status": "success"
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

def extract_words_from_text(text: str):
    """
    Extract individual English words from OCR text
    """
    # Remove special tokens and markdown
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'[*_#`]', '', text)
    
    # Extract words (3+ letters, English alphabet only)
    words = re.findall(r'\\b[A-Za-z]{3,}\\b', text)
    
    # Remove duplicates and return unique words
    unique_words = []
    seen = set()
    for word in words:
        word_lower = word.lower()
        if word_lower not in seen:
            # Filter out common words if needed
            if len(word_lower) >= 3:
                unique_words.append({
                    "text": word_lower,
                    "confidence": 0.95
                })
                seen.add(word_lower)
    
    print(f"Extracted {len(unique_words)} unique words")
    return unique_words

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model": "DeepSeek-OCR",
        "version": "2026-01"
    }

@app.get("/")
async def root():
    return {
        "message": "DeepSeek OCR API",
        "endpoints": {
            "/api/ocr/extract": "POST - Extract vocabulary from image",
            "/health": "GET - Health check"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
```

### 5. Run Backend Server

```bash
python backend_ocr_api.py
```

The API will be available at `http://localhost:8000`

You can test it by visiting: `http://localhost:8000/docs` (FastAPI automatic documentation)

## Update Flutter App

### 1. Update OCR Service URL

In `lib/services/ocr_service.dart`, update the `_baseUrl`:

```dart
// For local testing
static const String _baseUrl = 'http://192.168.1.100:8000/api';

// For production
static const String _baseUrl = 'https://your-domain.com/api';
```

### 2. Switch to Real OCR

In `lib/services/ocr_service.dart`, uncomment the real OCR call:

```dart
Future<List<DictionaryEntry>> extractVocabulary(String imagePath) async {
  try {
    // Use real OCR backend
    return await _callOcrBackend(imagePath);
    
    // Comment out mock data
    // return await _mockOcrExtraction(imagePath);
  } catch (e) {
    print('❌ Error in OCR extraction: $e');
    rethrow;
  }
}
```

### 3. Test the Integration

1. Start the Python backend
2. Get your server's IP address (e.g., `192.168.1.100`)
3. Update Flutter app with the IP
4. Run the Flutter app
5. Try creating a lesson with an image

## Deployment Options

### Option 1: Local Testing
- Run backend on your computer
- Use local IP address (e.g., `http://192.168.1.100:8000`)
- Connect phone and computer to same WiFi

### Option 2: Cloud Deployment

#### Deploy to Google Cloud Platform (GCP)
```bash
# Install gcloud CLI
gcloud init

# Deploy
gcloud run deploy deepseek-ocr \\
  --source . \\
  --platform managed \\
  --region us-central1 \\
  --allow-unauthenticated
```

#### Deploy to AWS EC2
1. Launch EC2 instance with GPU (g4dn.xlarge or better)
2. Install CUDA and dependencies
3. Clone your backend code
4. Run with systemd or PM2

#### Deploy to Heroku
```bash
heroku create your-ocr-backend
heroku stack:set container
git push heroku main
```

### Option 3: Use Docker

Create `Dockerfile`:

```dockerfile
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

WORKDIR /app

# Install Python
RUN apt-get update && apt-get install -y python3.10 python3-pip

# Copy requirements
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN pip install flash-attn==2.7.3 --no-build-isolation

# Copy code
COPY backend_ocr.py .

EXPOSE 8000

CMD ["python3", "backend_ocr.py"]
```

Build and run:
```bash
docker build -t deepseek-ocr-backend .
docker run -p 8000:8000 --gpus all deepseek-ocr-backend
```

## Testing

### Test Backend API

```bash
# Health check
curl http://localhost:8000/health

# Test OCR with image
curl -X POST http://localhost:8000/api/ocr/extract \\
  -F "image=@test_image.jpg"
```

### Test in Flutter App

1. Navigate to Archive Screen
2. Tap "Create Lesson"
3. Enter lesson name
4. Tap "Next"
5. Capture or select an image
6. Wait for OCR processing
7. Review and edit flashcards
8. Save lesson

## Performance Tips

1. **GPU Acceleration**: Use NVIDIA GPU for faster inference
2. **Model Caching**: Keep model loaded in memory
3. **Image Optimization**: Resize large images before processing
4. **Batch Processing**: Process multiple images together if needed
5. **Caching Results**: Cache OCR results to avoid re-processing

## Troubleshooting

### "CUDA out of memory"
- Reduce `base_size` and `image_size` parameters
- Process smaller images
- Use a GPU with more VRAM

### "Model download slow"
- Download model manually:
```bash
huggingface-cli download deepseek-ai/DeepSeek-OCR
```

### "Connection refused" from Flutter
- Check firewall settings
- Verify backend is running
- Use correct IP address
- Test with curl first

## Cost Estimation

### Self-hosting (AWS EC2 g4dn.xlarge)
- ~$0.526/hour = ~$380/month (full-time)
- GPU: NVIDIA T4 (16GB VRAM)

### Serverless (Google Cloud Run)
- Pay per request
- Cold start time: 30-60 seconds
- Better for low traffic

### Recommended for Development
- Local machine with GPU
- Or use mock data for testing UI first

## Security Considerations

1. **API Authentication**: Add API keys or JWT tokens
2. **Rate Limiting**: Prevent abuse
3. **Input Validation**: Validate image files
4. **HTTPS**: Use SSL certificates in production
5. **CORS**: Restrict allowed origins

## Next Steps

1. ✅ Set up Python backend with DeepSeek OCR
2. ✅ Test API endpoints
3. ✅ Update Flutter app with real API URL
4. ✅ Test complete flow
5. ⬜ Deploy to production server
6. ⬜ Add error handling and retry logic
7. ⬜ Optimize performance
8. ⬜ Add analytics and monitoring

## References

- [DeepSeek-OCR GitHub](https://github.com/deepseek-ai/DeepSeek-VL)
- [DeepSeek-OCR Hugging Face](https://huggingface.co/deepseek-ai/DeepSeek-OCR)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter HTTP Package](https://pub.dev/packages/http)
