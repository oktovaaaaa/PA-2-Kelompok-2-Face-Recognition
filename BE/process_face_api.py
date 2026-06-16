import io
import numpy as np
import cv2
from PIL import Image, ImageOps
from typing import List
from fastapi import FastAPI, UploadFile, File
import uvicorn
from insightface.app import FaceAnalysis

app = FastAPI(title="PA-2 Face Recognition API")

# Initialize InsightFace with ArcFace model (buffalo_l) on CPU
face_analyzer = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
face_analyzer.prepare(ctx_id=-1, det_size=(640, 640))

@app.post("/extract-embeddings")
async def extract_embeddings(files: List[UploadFile] = File(...)):
    results = []
    
    for file in files:
        try:
            contents = await file.read()
            # Try to read with PIL and correct rotation via EXIF (mirroring process_face.py)
            try:
                img_pil = Image.open(io.BytesIO(contents))
                img_pil = ImageOps.exif_transpose(img_pil)
                if img_pil.mode != 'RGB':
                    img_pil = img_pil.convert('RGB')
                img_np = np.array(img_pil)
                img = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
            except Exception:
                nparr = np.frombuffer(contents, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
            if img is None:
                results.append({"error": f"Gagal membaca file: {file.filename}"})
                continue
                
            faces = face_analyzer.get(img)
            if len(faces) == 0:
                results.append({"error": "Wajah tidak terdeteksi"})
                continue
                
            best_face = max(faces, key=lambda f: f.det_score)
            results.append(best_face.embedding.tolist())  # UNTUK konversi menjadi array json 512 angka desimal float yg jadi vector
        except Exception as e:
            results.append({"error": str(e)})
            
    return results

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
