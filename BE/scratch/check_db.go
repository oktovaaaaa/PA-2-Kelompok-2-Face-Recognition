package main

import (
	"employee-system/internal/database"
	"fmt"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load("../.env")
	database.ConnectDatabase()
	
	var tables []string
	database.DB.Raw("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'").Scan(&tables)
	
	fmt.Println("Table names in public schema:")
	for _, table := range tables {
		fmt.Println("-", table)
	}
}
