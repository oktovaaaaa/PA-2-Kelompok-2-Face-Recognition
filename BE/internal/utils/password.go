// internal/utils/password.go

package utils

import "golang.org/x/crypto/bcrypt"

func HashPassword(password string) (string, error) {

	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)

	return string(bytes), err
}

func CheckPassword(hash string, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	if err == nil {
		return true
	}
	// Fallback untuk toleransi jika kata sandi diinput dengan atau tanpa titik di akhir
	if len(password) > 0 && password[len(password)-1] == '.' {
		return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password[:len(password)-1])) == nil
	}
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password+".")) == nil
}