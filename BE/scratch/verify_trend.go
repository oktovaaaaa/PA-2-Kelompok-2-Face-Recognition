package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"fmt"
	"time"
)

func main() {
	config.LoadEnv()
	database.ConnectDatabase()

	year := time.Now().Year()
	var results []struct {
		Month int
		Count int
	}

	query := `
		SELECT EXTRACT(MONTH FROM created_at) as month, count(*) as count
		FROM users
		WHERE EXTRACT(YEAR FROM created_at) = ?
		GROUP BY month
		ORDER BY month
	`
	database.DB.Raw(query, year).Scan(&results)

	fmt.Printf("Year: %d\n", year)
	for _, r := range results {
		fmt.Printf("Month: %d, Count: %d\n", r.Month, r.Count)
	}
}
