import sys, json, os, numpy as np, cv2
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import tensorflow as tf
import logging
tf.get_logger().setLevel('ERROR')
logging.getLogger('tensorflow').setLevel(logging.ERROR)

# Load Face Detector (Haar Cascade)
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def detect_face_with_rotations(img):
    """Mencoba mendeteksi wajah dengan berbagai rotasi jika gagal di posisi awal"""
    for angle in [0, 90, -90, 180]:
        if angle == 0:
            rotated_img = img
        else:
            # Rotasi gambar
            (h, w) = img.shape[:2]
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, angle, 1.0)
            rotated_img = cv2.warpAffine(img, M, (w, h))
        
        gray = cv2.cvtColor(rotated_img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.1, 4)
        
        if len(faces) > 0:
            return rotated_img, faces[0]
            
    return None, None

def get_embedding(image_paths):
    try:
        model_path = os.path.join("assets", "mobilefacenet.tflite")
        if not os.path.exists(model_path):
            return {"error": f"Model tidak ditemukan di: {model_path}"}
            
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        results = []
        
        for path in image_paths:
            img = cv2.imread(path)
            if img is None:
                results.append({"error": f"Gagal membaca file: {path}"})
                continue
            
            # Gunakan fungsi deteksi dengan rotasi otomatis
            face_img_final, face_box = detect_face_with_rotations(img)
            
            if face_box is None:
                results.append({"error": "Wajah tidak terdeteksi"})
                continue
            
            # Potong wajah dari gambar yang sudah diputar dengan benar
            (x, y, w, h) = face_box
            face_crop = face_img_final[y:y+h, x:x+w]
            face_crop = cv2.resize(face_crop, (112, 112))
            face_crop = face_crop.astype(np.float32) / 255.0
            face_crop = np.expand_dims(face_crop, axis=0)
            
            interpreter.set_tensor(input_details[0]['index'], face_crop)
            interpreter.invoke()
            embedding = interpreter.get_tensor(output_details[0]['index'])[0]
            results.append(embedding.tolist())
            
        return results
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("JSON_START" + json.dumps({"error": "Path gambar diperlukan"}) + "JSON_END")
    else:
        image_paths = sys.argv[1:]
        print("JSON_START" + json.dumps(get_embedding(image_paths)) + "JSON_END")
        sys.stdout.flush()