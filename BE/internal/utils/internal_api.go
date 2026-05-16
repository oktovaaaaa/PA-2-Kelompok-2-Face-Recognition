package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// CallInternalAPI adalah helper untuk memanggil service lain
func CallInternalAPI(url string, target interface{}) error {
	client := &http.Client{Timeout: 10 * time.Second}
	
	resp, err := client.Get(url)
	if err != nil {
		return fmt.Errorf("gagal memanggil internal api: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("internal api mengembalikan status: %d", resp.StatusCode)
	}

	return json.NewDecoder(resp.Body).Decode(target)
}

func PostInternalAPI(url string, body interface{}) error {
	client := &http.Client{Timeout: 10 * time.Second}
	
	jsonBody, err := json.Marshal(body)
	if err != nil {
		return err
	}

	resp, err := client.Post(url, "application/json", bytes.NewBuffer(jsonBody))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("internal api mengembalikan status: %d", resp.StatusCode)
	}

	return nil
}
