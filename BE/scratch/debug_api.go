package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	// Ganti ID dengan ID Osvald yang valid (dari log sebelumnya: 4ccd8470-b79c-48c1-9180-bd90b80569a3)
	id := "4ccd8470-b79c-48c1-9180-bd90b80569a3"
	url := "http://localhost:8081/api/internal/users/single?id=" + id

	resp, err := http.Get(url)
	if err != nil {
		fmt.Printf("Gagal panggil API: %v\n", err)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Println("\n=== RESPON API INTERNAL AUTH ===")
	fmt.Println(string(body))
	fmt.Println("================================\n")
}
