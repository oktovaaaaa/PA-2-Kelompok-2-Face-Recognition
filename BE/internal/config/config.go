// internal/config/config.go

package config

import (
	"log"

	"github.com/joho/godotenv"
)

func LoadEnv(filenames ...string) {
	var err error
	if len(filenames) > 0 {
		err = godotenv.Load(filenames...)
	} else {
		err = godotenv.Load()
	}

	if err != nil {
		log.Println("File .env tidak ditemukan atau gagal dimuat")
	}
}