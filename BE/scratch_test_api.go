package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

func main() {
	// We can't easily get a valid token here, but we can try to call the internal API directly
	// to see if the handler itself works.
	resp, err := http.Get("http://localhost:8081/api/internal/users?company_id=25ab05d5-5fbd-46df-a9e6-27f79d786f13")
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}
	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)
	fmt.Printf("Status: %s\n", resp.Status)
	fmt.Printf("Body: %s\n", string(body))
}
