// internal/utils/pin.go
package utils

import "golang.org/x/crypto/bcrypt"

func HashPin(pin string) (string, error) {

	hash, err := bcrypt.GenerateFromPassword([]byte(pin), bcrypt.DefaultCost)

	return string(hash), err
}

func CheckPin(hash string, pin string) bool {

	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(pin))

	return err == nil
}