package services

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// ProcessFaceImages takes base64 images and returns the mean embedding as a JSON string
func ProcessFaceImages(images []string) (string, error) {
	if len(images) == 0 {
		return "", fmt.Errorf("tidak ada gambar untuk diproses")
	}

	// Simpan semua gambar ke file temporary
	var tempFiles []string
	for i, b64 := range images {
		tempFile, err := os.CreateTemp("", fmt.Sprintf("face_reg_%d_*.jpg", i))
		if err != nil {
			continue
		}
		imgData, err := base64.StdEncoding.DecodeString(b64)
		if err != nil {
			os.Remove(tempFile.Name())
			continue
		}
		tempFile.Write(imgData)
		tempFile.Close()
		tempFiles = append(tempFiles, tempFile.Name())
	}
	defer func() {
		for _, f := range tempFiles {
			os.Remove(f)
		}
	}()

	if len(tempFiles) == 0 {
		return "", fmt.Errorf("gagal menyimpan gambar ke file temporary")
	}

	// Jalankan Python untuk semua gambar sekaligus
	args := append([]string{"process_face.py"}, tempFiles...)
	cmd := exec.Command("python", args...)
	output, err := cmd.CombinedOutput()
	
	outStr := string(output)

	if err != nil {
		return "", fmt.Errorf("Gagal menjalankan AI Engine: %v | Output: %s", err, outStr)
	}
	
	var jsonStr string
	
	startTag := "JSON_START"
	endTag := "JSON_END"
	
	startIdx := strings.Index(outStr, startTag)
	endIdx := strings.LastIndex(outStr, endTag)
	
	if startIdx != -1 && endIdx != -1 && endIdx > startIdx {
		jsonStr = outStr[startIdx+len(startTag) : endIdx]
	} else {
		return "", fmt.Errorf("AI Error: Data tidak ditemukan dalam output. Pastikan semua library python (tensorflow, opencv, numpy) sudah terinstall. | Output: %s", outStr)
	}

	var allResults []interface{}
	if err := json.Unmarshal([]byte(jsonStr), &allResults); err != nil {
		return "", fmt.Errorf("gagal mengurai data AI: %w", err)
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
