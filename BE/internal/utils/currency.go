package utils

import (
	"strconv"
)

// FormatRupiah mencetak angka dengan format "Rp 1.000.000"
func FormatRupiah(amount float64) string {
	n := int64(amount)
	s := strconv.FormatInt(n, 10)
	
	// Handle negatif jika ada
	prefix := ""
	if n < 0 {
		prefix = "-"
		s = s[1:]
	}

	if len(s) <= 3 {
		return prefix + "Rp " + s
	}

	var res []byte
	for i := 0; i < len(s); i++ {
		if i > 0 && (len(s)-i)%3 == 0 {
			res = append(res, '.')
		}
		res = append(res, s[i])
	}
	return prefix + "Rp " + string(res)
}
