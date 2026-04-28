package main

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func dropConstraints(dbName string) {
	fmt.Printf("\nDropping constraints in %s...\n", dbName)
	
	dsn := fmt.Sprintf("host=localhost user=postgres password=postgres dbname=%s port=5432 sslmode=disable", dbName)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		fmt.Printf("Error connecting to %s: %v\n", dbName, err)
		return
	}

	// Try both singular and plural table names
	tables := []string{"bonus", "bonuses", "penalty", "penalties", "salary", "salaries", "attendance", "attendances", "leave_request", "leave_requests"}
	
	for _, t := range tables {
		// Drop constraints
		constraintName := fmt.Sprintf("fk_%s_user", t)
		query := fmt.Sprintf("ALTER TABLE %s DROP CONSTRAINT IF EXISTS %s", t, constraintName)
		
		if err := db.Exec(query).Error; err != nil {
			// Ignore if table doesn't exist
		} else {
			fmt.Printf("Success: %s\n", query)
		}
	}
}

func main() {
	dropConstraints("pa2_payroll")
	dropConstraints("pa2_attendance")
}
