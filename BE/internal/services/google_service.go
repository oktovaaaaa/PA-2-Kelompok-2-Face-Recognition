// internal/services/google_service.go
package services

import (
	"context"
	"os"

	"google.golang.org/api/idtoken"
)

func VerifyGoogleToken(token string) (*idtoken.Payload, error) {
	// Daftar Client ID yang diijinkan (Web & Android)
	audiences := []string{
		os.Getenv("GOOGLE_CLIENT_ID"),
		os.Getenv("GOOGLE_CLIENT_ID_ANDROID"),
	}

	var lastErr error
	for _, aud := range audiences {
		if aud == "" {
			continue
		}

		payload, err := idtoken.Validate(
			context.Background(),
			token,
			aud,
		)

		if err == nil {
			return payload, nil
		}
		lastErr = err
	}

	return nil, lastErr
}

// untuk memferivikasi id_token dari google 