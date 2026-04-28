package utils

import "strings"

// CaseInsensitiveContains reports whether substr is within s, ignoring case.
func CaseInsensitiveContains(s, substr string) bool {
	s, substr = strings.ToLower(s), strings.ToLower(substr)
	return strings.Contains(s, substr)
}
