// scratch/debug_bonus_query.go
package main

import (
	"employee-system/internal/models"
	"fmt"
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	dsn := "host=localhost user=postgres password=root dbname=employee_system port=5432 sslmode=disable TimeZone=Asia/Jakarta"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("=== Checking Admins ===")
	var admins []models.User
	db.Where("role = ?", "ADMIN").Find(&admins)
	for _, a := range admins {
		fmt.Printf("Admin: %s (ID: %s), CompanyID: %s\n", a.Name, a.ID, a.CompanyID)
	}

	if len(admins) == 0 {
		fmt.Println("No admins found!")
		return
	}
	admin := admins[0]

	fmt.Println("\n=== Checking Employees ===")
	var employees []models.User
	db.Where("company_id = ?", admin.CompanyID).Find(&employees)
	for _, e := range employees {
		fmt.Printf("Employee: %s (ID: %s), Role: %s, Status: %s\n", e.Name, e.ID, e.Role, e.Status)
	}

	fmt.Println("\n=== Checking Bonuses directly ===")
	var allBonuses []models.Bonus
	db.Find(&allBonuses)
	fmt.Printf("Total bonuses in table: %d\n", len(allBonuses))
	for _, b := range allBonuses {
		fmt.Printf("Bonus: %s, Amount: %f, Date: %s, UserID: %s\n", b.Title, b.Amount, b.Date, b.UserID)
	}

	fmt.Println("\n=== Simulating AdminGetBonuses Query ===")
	db = db.Debug() // Enable debug mode for visibility
	var filteredBonuses []models.Bonus
	query := db.Model(&models.Bonus{}).
		Joins("JOIN users ON users.id = bonuses.user_id").
		Where("users.company_id = ?", admin.CompanyID)
	
	// Simulating April 2026
	year := "2026"
	
	// Apply Month/Year LIKE filters
	mInt := 4
	query = query.Where("bonuses.date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, mInt))
	
	var total int64
	query.Count(&total)
	fmt.Printf("Count result: %d\n", total)

	query.Preload("User").Select("bonuses.*").Find(&filteredBonuses)
	fmt.Printf("Find result count: %d\n", len(filteredBonuses))
}
