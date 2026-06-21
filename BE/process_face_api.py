import io  # Bawaan Python: Untuk membaca file gambar langsung dari memori (bytes)
import numpy as np  # Library numpy: Untuk mengubah gambar menjadi format array angka
import cv2  # Library opencv-python: Untuk manipulasi & konversi format warna gambar (RGB ke BGR)
from PIL import Image, ImageOps  # Library Pillow: Untuk membuka gambar & rotasi otomatis agar tidak miring
from typing import List  # Bawaan Python: Untuk tipe data list pada parameter API
from fastapi import FastAPI, UploadFile, File  # Library fastapi: Untuk membuat web API & menangani file upload
import uvicorn  # Library uvicorn: Web server untuk menjalankan aplikasi FastAPI
from insightface.app import FaceAnalysis  # Library insightface: Model AI utama untuk deteksi & ekstraksi wajah



# ==============================================================================
# PERBEDAAN PROCESS_FACE_API.PY (API BARU) VS PROCESS_FACE.PY (SCRIPT CLI LAMA):
# - process_face_api.py (File Ini): Berjalan sebagai service API yang standby terus.
#   Model 'buffalo_l' (ArcFace) di-load ke RAM hanya SATU KALI saat server dinyalakan.
#   Ketika ada request registrasi atau check-in (ke endpoint '/extract-embeddings'), 
#   API langsung memproses gambar tanpa perlu memuat model lagi. Sangat cepat (<0.5 detik).
# - process_face.py (Lama): Berupa script CLI yang memuat model 'buffalo_l' dari awal 
#   setiap kali dijalankan, yang membuat respon menjadi lambat (~2-4 detik per request).
# ==============================================================================

app = FastAPI(title="PA-2 Face Recognition API")

# Memuat model 'buffalo_l' ke memori SEKALI SAJA saat server dijalankan.
# Parameter 'providers': Menggunakan ONNX Runtime (library eksekusi model AI .onnx) dengan pilihan 'CPUExecutionProvider' untuk memproses model menggunakan CPU.
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

if __name__ == "__main__": # yang buat function ini standby di ram 
    uvicorn.run(app, host="0.0.0.0", port=5000)
