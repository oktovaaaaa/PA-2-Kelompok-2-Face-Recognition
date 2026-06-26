package utils

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"io"
	"os"
)

// getAESKey mengambil kunci enkripsi AES dari environment variable 'AES_SECRET_KEY'.
// Jika environment variable kosong atau kurang dari 32 byte, fungsi ini akan mengembalikan
// kunci default statis 32-byte (256-bit) agar sistem tidak crash/error.
func getAESKey() []byte {
	secret := os.Getenv("AES_SECRET_KEY")
	if len(secret) < 32 {
		// Fallback key 32-byte default untuk enkripsi AES-256
		return []byte("videnti-pa2-super-secret-key-32b")
	}
	// Mengambil 32 karakter pertama untuk dijadikan kunci AES-256
	return []byte(secret[:32])
}

// Encrypt mengenkripsi teks biasa (plainText) menggunakan mode AES-GCM (Authenticated Encryption).
// Hasil enkripsi dikembalikan dalam format string Base64 agar aman disimpan di kolom teks database.
func Encrypt(plainText string) (string, error) {
	// Jika teks yang akan dienkripsi kosong, langsung kembalikan string kosong
	if plainText == "" {
		return "", nil
	}

	// 1. Membuat cipher block baru berbasis kunci AES 256-bit kita
	block, err := aes.NewCipher(getAESKey())
	if err != nil {
		return "", err
	}

	// 2. Menginisialisasi Galois Counter Mode (GCM) cipher generator
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// 3. Membuat Nonce (Number Used Once) acak dengan ukuran standar GCM (12-byte)
	// Nonce sangat penting dalam kriptografi modern agar teks yang sama tidak menghasilkan enkripsi yang sama.
	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	// 4. Melakukan enkripsi data (Seal). Kita menempelkan nonce di bagian awal (prefix)
	// data terenkripsi agar nanti saat didekripsi, nonce tersebut bisa dibaca kembali.
	ciphertext := gcm.Seal(nonce, nonce, []byte(plainText), nil)

	// 5. Mengubah biner data terenkripsi menjadi string Base64 yang aman dibaca database
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt mengembalikan data asli (plainText) dari string Base64 terenkripsi (cryptoText).
// Fungsi ini secara otomatis memisahkan nonce dan melakukan dekripsi & verifikasi integritas data (GCM).
func Decrypt(cryptoText string) (string, error) {
	// Jika teks kosong, langsung kembalikan string kosong
	if cryptoText == "" {
		return "", nil
	}

	// 1. Mengubah string Base64 kembali menjadi bentuk byte mentah (ciphertext)
	ciphertext, err := base64.StdEncoding.DecodeString(cryptoText)
	if err != nil {
		return "", err
	}

	// 2. Membuat cipher block baru berbasis kunci AES 256-bit kita
	block, err := aes.NewCipher(getAESKey())
	if err != nil {
		return "", err
	}

	// 3. Menginisialisasi Galois Counter Mode (GCM)
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// 4. Memastikan ukuran ciphertext cukup panjang untuk menampung nonce minimum
	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		return "", errors.New("ukuran data terenkripsi terlalu pendek")
	}

	// 5. Memisahkan nonce (di awal data) dan data terenkripsi yang sesungguhnya (setelah nonce)
	nonce, actualCiphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]

	// 6. Melakukan dekripsi dan verifikasi keaslian/integrititas data.
	// Jika data dirusak/diubah di database secara tidak sah, fungsi Open akan mengembalikan error.
	plainTextBytes, err := gcm.Open(nil, nonce, actualCiphertext, nil)
	if err != nil {
		return "", err
	}

	// 7. Mengembalikan data asli dalam bentuk string
	return string(plainTextBytes), nil
}
