// cmd/server/main.go

package main

import (
	"fmt"
	"os"

	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/services"
	"employee-system/routes"
)

func main() {

	config.LoadEnv()

	database.ConnectDatabase()
	services.StartScheduler()

	r := routes.SetupRouter()

	port := os.Getenv("APP_PORT")

	if port == "" {
		port = "8080"
	}

	fmt.Println("Server berjalan di port", port)

	r.Run(":" + port)
}
