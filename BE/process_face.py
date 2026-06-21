import sys, json, os, numpy as np, cv2  # Modul bawaan & eksternal untuk sistem, JSON, manipulasi array (numpy), dan pemrosesan gambar (OpenCV)
import logging  # Bawaan Python: Untuk menampilkan log kesalahan (error logging)
logging.basicConfig(level=logging.ERROR)

import warnings  # Bawaan Python: Untuk mengabaikan pesan peringatan (warning) sistem
warnings.filterwarnings("ignore")

from PIL import Image, ImageOps  # Library Pillow: Untuk membuka gambar & rotasi otomatis agar tidak miring
import insightface  # Library utama untuk pengenalan wajah (Face Recognition)
from insightface.app import FaceAnalysis  # Class dari InsightFace untuk pipeline deteksi & ekstraksi wajah


# ==============================================================================
# PERBEDAAN PROCESS_FACE.PY (SCRIPT CLI LAMA) VS PROCESS_FACE_API.PY (API BARU):
# - process_face.py (File Ini): Dijalankan sebagai script CLI sekali jalan. 
#   Setiap kali ada request registrasi/check-in, sistem Go backend akan mengeksekusi 
#   script ini dari awal. Kelemahannya: Sistem harus memuat model 'buffalo_l' 
#   ke RAM dari awal setiap kali dipanggil, yang memakan waktu (overhead ~2-4 detik).
# - process_face_api.py (API): Berjalan terus-menerus sebagai server API (FastAPI).
#   Model 'buffalo_l' hanya dimuat SEKALI saat server dinyalakan. Saat ada registrasi/check-in,
#   Go backend cukup memanggil endpoint HTTP POST sehingga prosesnya instan (<0.5 detik).
# ==============================================================================

# Inisialisasi model 'buffalo_l'. Pada script CLI lama ini, model akan di-load 
# ke memori SETIAP KALI script ini dipanggil lewat perintah terminal/exec command.
# Parameter 'providers': Menggunakan ONNX Runtime (library eksekusi model AI .onnx) dengan pilihan 'CPUExecutionProvider' untuk memproses model menggunakan CPU.
app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
app.prepare(ctx_id=-1, det_size=(640, 640))

def get_embedding(image_paths):
    
    try:
        results = []
        
        for path in image_paths:
            try:
                # Load with PIL & auto-rotate via EXIF
                img_pil = Image.open(path)
                img_pil = ImageOps.exif_transpose(img_pil)
                if img_pil.mode != 'RGB':
                    img_pil = img_pil.convert('RGB')
                img_np = np.array(img_pil)
                img = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
            except Exception:
                img = cv2.imread(path)
                
            if img is None:
                results.append({"error": f"Gagal membaca file: {path}"})
                continue
                
            faces = app.get(img)
            if len(faces) == 0:
                results.append({"error": "Wajah tidak terdeteksi"})
                continue
                
            best_face = max(faces, key=lambda f: f.det_score)
            results.append(best_face.embedding.tolist())
            
        return results
    except Exception as e:
        return [{"error": str(e)}]


if __name__ == "__main__":
    # Memeriksa apakah argumen baris perintah kurang dari 2 (artinya tidak ada file foto yang dikirim dari backend)
    if len(sys.argv) < 2:
        # Menampilkan pesan error dalam format JSON yang diawali "JSON_START" dan diakhiri "JSON_END" agar mudah di-parsing Go
        print("JSON_START" + json.dumps([{"error": "Path gambar diperlukan"}]) + "JSON_END")
    else:
        # Mengambil semua argumen baris perintah mulai dari indeks ke-1 (daftar lokasi/path file gambar)
        image_paths = sys.argv[1:]
        # Mengekstrak embedding wajah, mengubahnya ke format JSON, lalu mencetaknya di antara tanda pembatas "JSON_START" & "JSON_END"
        print("JSON_START" + json.dumps(get_embedding(image_paths)) + "JSON_END")
        # Memaksa terminal untuk segera mengirimkan output teks (buffer flush) ke backend tanpa menunggu proses Python selesai
        sys.stdout.flush()