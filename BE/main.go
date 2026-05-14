package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type User struct {
	ID        uint   `gorm:"primaryKey"`
	Name      string `gorm:"unique;not null" json:"name"`
	Password  string `json:"password"`
	Embedding string `gorm:"type:text" json:"embedding"`
	Liveness  bool   `json:"liveness"`
}

var DB *gorm.DB

func initDB() {
	godotenv.Load()
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"), os.Getenv("DB_PORT"))
	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("Gagal DB")
	}
	DB.AutoMigrate(&User{})
}

func getEmbedding(b64 string) ([]float32, error) {
	data, err := base64.StdEncoding.DecodeString(b64)
	if err != nil {
		return nil, err
	}
	tmp := filepath.Join(os.TempDir(), fmt.Sprintf("f_tmp_%d.jpg", os.Getpid()))
	os.WriteFile(tmp, data, 0644)
	defer os.Remove(tmp)

	fmt.Println("--> Memproses wajah dengan Python...")
	cmd := exec.Command("python", "process_face.py", tmp)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("Python error: %v, Output: %s", err, string(out))
	}
	
	// Mencari baris yang mengandung "RESULT:"
	outStr := string(out)
	var jsonStr string
	lines := strings.Split(outStr, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "RESULT:") {
			jsonStr = strings.TrimPrefix(line, "RESULT:")
			break
		}
	}
	
	if jsonStr == "" {
		return nil, fmt.Errorf("Output Python tidak mengandung hasil (RESULT): %s", outStr)
	}
	
	var result map[string]interface{}
	if err := json.Unmarshal([]byte(jsonStr), &result); err == nil {
		if errStr, ok := result["error"]; ok {
			return nil, fmt.Errorf("%v", errStr)
		}
	}

	var emb []float32
	if err := json.Unmarshal([]byte(jsonStr), &emb); err != nil {
		return nil, fmt.Errorf("Gagal mengurai embedding: %v", err)
	}
	return emb, nil
}

func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

func main() {
	initDB()
	r := gin.Default()
	
	// Tambahkan ini agar Gin tidak langsung 404 saat menerima request OPTIONS
	r.HandleMethodNotAllowed = true
	
	r.Use(CORSMiddleware())

	r.POST("/register", func(c *gin.Context) {
		var in struct {
			Name     string   `json:"name"`
			Password string   `json:"password"`
			Images   []string `json:"images"`
			Liveness bool     `json:"liveness_verified"`
		}
		if err := c.BindJSON(&in); err != nil {
			c.JSON(400, gin.H{"message": "Invalid input"})
			return
		}
		if len(in.Images) == 0 {
			c.JSON(400, gin.H{"message": "Data wajah tidak lengkap"})
			return
		}

		fmt.Printf("--> Menerima register: %s dengan %d gambar\n", in.Name, len(in.Images))

		var meanEmb []float32
		var count int
		for _, imgB64 := range in.Images {
			emb, err := getEmbedding(imgB64)
			if err != nil {
				fmt.Printf("--> Gagal proses salah satu gambar: %v\n", err)
				continue
			}
			if meanEmb == nil {
				meanEmb = make([]float32, len(emb))
			}
			for i := range emb {
				meanEmb[i] += emb[i]
			}
			count++
		}

		if count == 0 {
			c.JSON(400, gin.H{"message": "Gagal mengekstrak fitur wajah dari semua gambar"})
			return
		}

		for i := range meanEmb {
			meanEmb[i] /= float32(count)
		}

		embS, _ := json.Marshal(meanEmb)
		err := DB.Create(&User{
			Name:      in.Name,
			Password:  in.Password,
			Embedding: string(embS),
			Liveness:  in.Liveness,
		}).Error

		if err != nil {
			if strings.Contains(err.Error(), "duplicate key") {
				c.JSON(400, gin.H{"message": "Nama user sudah terdaftar"})
			} else {
				c.JSON(500, gin.H{"message": "Database error: " + err.Error()})
			}
			return
		}

		c.JSON(200, gin.H{"message": "Berhasil Daftar dengan " + fmt.Sprint(count) + " titik data"})
	})

	r.POST("/login", func(c *gin.Context) {
		var in struct{ Name, Password string }
		c.BindJSON(&in)
		var u User
		if err := DB.Where("name = ? AND password = ?", in.Name, in.Password).First(&u).Error; err != nil {
			c.JSON(401, gin.H{"message": "Gagal Login"})
			return
		}
		c.JSON(200, gin.H{"message": "Berhasil Login"})
	})

	r.POST("/verify", func(c *gin.Context) {
		var in struct{ Name, Image string }
		c.BindJSON(&in)
		embNew, err := getEmbedding(in.Image)
		if err != nil {
			c.JSON(400, gin.H{"message": err.Error()})
			return
		}
		var u User
		if err := DB.Where("name = ?", in.Name).First(&u).Error; err != nil {
			c.JSON(404, gin.H{"message": "User tidak ditemukan"})
			return
		}
		var embOld []float32
		json.Unmarshal([]byte(u.Embedding), &embOld)

		var dot, n1, n2 float32
		for i := range embNew {
			dot += embNew[i] * embOld[i]
			n1 += embNew[i] * embNew[i]
			n2 += embOld[i] * embOld[i]
		}
		score := dot / (float32(math.Sqrt(float64(n1))) * float32(math.Sqrt(float64(n2))))
		fmt.Printf("--> Verifikasi %s: Skor Kemiripan = %.4f\n", in.Name, score)

		if score > 0.65 {
			c.JSON(200, gin.H{"status": "Sukses", "score": score})
		} else {
			c.JSON(401, gin.H{"status": "Gagal", "score": score})
		}
	})
	r.Run(":8080")
}
