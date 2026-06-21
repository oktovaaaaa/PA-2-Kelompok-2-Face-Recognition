package services

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"time"
)

// ProcessFaceImages takes base64 images and returns the mean embedding as a JSON string
func ProcessFaceImages(images []string) (string, error) {
	if len(images) == 0 {
		return "", fmt.Errorf("tidak ada gambar untuk diproses")
	}

	// Buat buffer untuk multipart form data
	var b bytes.Buffer
	w := multipart.NewWriter(&b)

	for i, b64 := range images {
		imgData, err := base64.StdEncoding.DecodeString(b64)
		if err != nil {
			return "", fmt.Errorf("gagal mendekode base64 gambar ke-%d: %w", i, err)
		}

		fw, err := w.CreateFormFile("files", fmt.Sprintf("face_%d.jpg", i))
		if err != nil {
			return "", fmt.Errorf("gagal membuat form file untuk gambar ke-%d: %w", i, err)
		}
		if _, err := io.Copy(fw, bytes.NewReader(imgData)); err != nil {
			return "", fmt.Errorf("gagal menulis data gambar ke-%d ke form: %w", i, err)
		}
	}
	w.Close()

	// Kirim POST request ke Python API
	client := &http.Client{Timeout: 30 * time.Second}
	req, err := http.NewRequest("POST", "http://localhost:5000/extract-embeddings", &b) // 
	if err != nil {
		return "", fmt.Errorf("gagal membuat request HTTP ke AI engine: %w", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())
	
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("gagal menghubungi AI Engine: %w. Pastikan Python service sudah berjalan.", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("AI Engine mengembalikan status error: %d, body: %s", resp.StatusCode, string(bodyBytes))
	}

	// Parse respon JSON
	var allResults []interface{}
	if err := json.NewDecoder(resp.Body).Decode(&allResults); err != nil {
		return "", fmt.Errorf("gagal mengurai respon dari AI Engine: %w", err)
	}

	var validEmbeddings [][]float32
	for _, res := range allResults {
		if emb, ok := res.([]interface{}); ok {
			var floatEmb []float32
			for _, v := range emb {
				floatEmb = append(floatEmb, float32(v.(float64)))
			}
			validEmbeddings = append(validEmbeddings, floatEmb)
		}
	}

	if len(validEmbeddings) == 0 {
		// Cek jika ada error di elemen pertama
		if len(allResults) > 0 {
			if errMap, ok := allResults[0].(map[string]interface{}); ok {
				if errMsg, exists := errMap["error"]; exists {
					return "", fmt.Errorf("%v", errMsg)
				}
			}
		}
		return "", fmt.Errorf("tidak ada wajah valid yang terdeteksi")
	}

	// Hitung Rata-rata (Mean Embedding)
	embSize := len(validEmbeddings[0])
	meanEmb := make([]float32, embSize)
	for _, emb := range validEmbeddings {
		for i := 0; i < embSize; i++ {
			meanEmb[i] += emb[i]
		}
	}
	for i := 0; i < embSize; i++ {
		meanEmb[i] /= float32(len(validEmbeddings))
	}

	embS, _ := json.Marshal(meanEmb)
	return string(embS), nil
}

