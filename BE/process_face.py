import sys, json, os, numpy as np, cv2
import logging
logging.basicConfig(level=logging.ERROR)

# Suppress unnecessary warnings
import warnings
warnings.filterwarnings("ignore")

# PIL for EXIF-based rotation correction
from PIL import Image, ImageOps

# InsightFace for face detection + alignment + embedding
import insightface
from insightface.app import FaceAnalysis

# Initialize InsightFace with ArcFace model (buffalo_l)
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
    if len(sys.argv) < 2:
        print("JSON_START" + json.dumps([{"error": "Path gambar diperlukan"}]) + "JSON_END")
    else:
        image_paths = sys.argv[1:]
        print("JSON_START" + json.dumps(get_embedding(image_paths)) + "JSON_END")
        sys.stdout.flush()