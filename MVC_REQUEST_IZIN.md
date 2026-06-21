# Penjelasan Model-View-Controller (MVC) - Fitur Request Izin

Dokumen ini menjelaskan penerapan pola arsitektur **Model-View-Controller (MVC)** khusus pada fitur **Request Izin (Pengajuan Cuti/Sakit)** di dalam project ini.

---

## 1. Alur Kerja MVC pada Request Izin
Secara umum, alur data saat seorang Karyawan mengajukan izin adalah sebagai berikut:
1. **View (Flutter/Web)**: Karyawan mengisi form izin (tipe, tanggal, judul, keterangan, bukti foto) dan menekan tombol **"Ajukan Izin"**.
2. **Request HTTP**: View memanggil API Client untuk mengirim data (payload JSON) ke backend melalui HTTP POST `/api/employee/leaves`.
3. **Controller (Go Handler)**: Backend menerima request tersebut, melakukan validasi (apakah data lengkap, apakah konfirmasi jujur diisi), mengolah data, dan menyimpannya menggunakan ORM GORM.
4. **Model (Go Struct)**: Data dibungkus ke dalam struktur objek database `LeaveRequest`.
5. **Database**: GORM memetakan objek Model tersebut ke tabel `leave_requests` di database PostgreSQL.
6. **Response**: Controller mengirimkan status response sukses/gagal kembali ke View untuk ditampilkan ke pengguna.

---

## 2. Implementasi Kodingan

### A. MODEL (Representasi & Struktur Data)
Model mendefinisikan skema data dan bagaimana data izin disimpan di dalam database.
* **File Source:** [leave_request.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/models/leave_request.go)

```go
package models

import "time"

// LeaveRequest adalah pengajuan izin atau sakit dari karyawan.
type LeaveRequest struct {
	ID        string `gorm:"primaryKey" json:"id"`
	UserID    string `gorm:"index" json:"user_id"`
	User      User   `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`

	CompanyID string `gorm:"index" json:"company_id"`
	Company   Company `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`

	// Tipe pengajuan: IZIN | SAKIT
	Type string `json:"type"`

	Title       string `json:"title"`
	Description string `json:"description"`
	PhotoURL    string `json:"photo_url"`

	// Status pengajuan: PENDING | APPROVED | REJECTED
	Status    string `json:"status"`
	AdminNote string `json:"admin_note"`

	// Karyawan menyatakan tidak memalsukan data (Pernyataan Kejujuran)
	ConfirmedHonest bool `json:"confirmed_honest"`

	// Soft-delete per pihak: data benar-benar terhapus hanya jika keduanya true
	IsDeletedByEmployee bool `json:"is_deleted_by_employee"`
	IsDeletedByAdmin    bool   `json:"is_deleted_by_admin"`
	
	// Daftar tanggal terpilih dalam bentuk JSON string (e.g. ["2026-06-17", "2026-06-18"])
	Dates               string `json:"dates"` 

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
```

---

### B. CONTROLLER (Logika Bisnis & Penanganan Request)
Controller bertindak sebagai jembatan antara View dan Model. Di backend Go, Controller diimplementasikan sebagai **Handler**.
* **File Source:** [leave_handler.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/handlers/leave_handler.go)

Berikut potongan kode controller saat **Karyawan membuat pengajuan izin** (`EmployeeCreateLeave`):

```go
// EmployeeCreateLeave — karyawan mengajukan izin/sakit
func EmployeeCreateLeave(c *gin.Context) {
	// 1. Ambil data identitas karyawan yang terverifikasi dari context jwt
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	// 2. Definisikan struktur body JSON yang diterima
	var body struct {
		Type            string   `json:"type"`
		Title           string   `json:"title"`
		Description     string   `json:"description"`
		PhotoURL        string   `json:"photo_url"`
		ConfirmedHonest bool     `json:"confirmed_honest"`
		Dates           []string `json:"dates"` 
	}
	
	// 3. Ikat body json request permohonan izin dari frontend hp
	if err := c.ShouldBindJSON(&body); err != nil || body.Title == "" || body.Type == "" || len(body.Dates) == 0 {
		utils.Error(c, "Data izin tidak lengkap (pastikan tanggal sudah dipilih)")
		return
	}
	
	// 4. Validasi kejujuran data & tipe izin
	if !body.ConfirmedHonest {
		utils.Error(c, "Kamu harus mengkonfirmasi kejujuran data izin")
		return
	}
	if body.Type != "IZIN" && body.Type != "SAKIT" {
		utils.Error(c, "Tipe izin tidak valid (IZIN / SAKIT)")
		return
	}

	// 5. Ubah array list tanggal yang dipilih menjadi representasi json string
	datesJSON, _ := json.Marshal(body.Dates)

	// 6. Buat objek baru Model LeaveRequest dengan status default PENDING
	leave := models.LeaveRequest{
		ID:              uuid.New().String(),
		UserID:          emp.ID,
		CompanyID:       emp.CompanyID,
		Type:            body.Type,
		Title:           body.Title,
		Description:     body.Description,
		PhotoURL:        body.PhotoURL,
		Status:          "PENDING",
		ConfirmedHonest: body.ConfirmedHonest,
		Dates:           string(datesJSON),
	}
	
	// 7. Simpan record permohonan izin ke database menggunakan GORM
	if err := database.DB.Create(&leave).Error; err != nil {
		utils.Error(c, "Gagal membuat izin")
		return
	}

	// 8. Kirim notifikasi secara asynchronous ke Admin (in-app & Firebase Push Notification)
	// (Proses pengiriman notifikasi ke admin perusahaan...)

	// 9. Kirim response sukses ke View
	utils.Success(c, "Izin berhasil diajukan", leave)
}
```

---

### C. VIEW (Antarmuka Pengguna/User Interface)
View adalah representasi visual dari data yang berinteraksi langsung dengan pengguna.
* **Mobile View (Karyawan):** [employee_leave_tab.dart](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/FE/lib/features/employee/presentation/screens/tabs/employee_leave_tab.dart)
* **Web View (Admin):** [LeaveCalendar.tsx](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/admin-web-next/src/views/cuti/LeaveCalendar.tsx)

Berikut contoh potongan View pada Flutter mobile saat menyusun data dan memanggil API:

```dart
// Event handler saat tombol "Ajukan Izin" ditekan
onPressed: () async {
  Navigator.pop(ctx);
  
  // 1. Upload foto bukti ke server terlebih dahulu jika ada
  if (pickedPhoto != null) {
    final uploadRes = await ApiClient.uploadFile(pickedPhoto!);
    if (uploadRes.success) {
      uploadedPhotoUrl = uploadRes.data?['url'] as String?;
    }
  }
  
  // 2. Kumpulkan daftar tanggal yang dipilih dari kalender
  List<String> datesToSend = selectedDates
      .where((d) => d != null)
      .map((d) => DateFormat('yyyy-MM-dd').format(d!))
      .toList();

  if (datesToSend.isEmpty) {
    AppDialog.showError(context, 'Pilih minimal satu tanggal');
    return;
  }

  // 3. Susun payload JSON (Data yang akan dikirim ke Controller/Backend)
  final body = {
    'type': selectedType, // "IZIN" atau "SAKIT"
    'title': titleCtrl.text.trim(),
    'description': descCtrl.text.trim(),
    'photo_url': uploadedPhotoUrl ?? '',
    'confirmed_honest': confirmed,
    'dates': datesToSend,
  };

  try {
    // 4. Kirim data ke Controller lewat API Client
    final res = isEdit
        ? await ApiClient.put('/api/employee/leaves/${existing!['id']}', body)
        : await ApiClient.post('/api/employee/leaves', body);
        
    if (!mounted) return;
    
    // 5. Tampilkan dialog respon balik ke user berdasarkan hasil dari Controller
    if (res.success) {
      AppDialog.showSuccess(context, isEdit ? 'Izin diperbarui' : 'Izin berhasil diajukan!');
      _load(); // Muat ulang list riwayat izin (View terupdate otomatis)
    } else {
      AppDialog.showError(context, res.message ?? 'Gagal memproses izin');
    }
  } catch (_) {}
}
```

---

## 3. Catatan Penting (Notes Tambahan)

1. **Pemisahan Tanggung Jawab (Separation of Concerns)**:
   - **View** tidak boleh melakukan query database secara langsung. View hanya bertugas menampilkan data dan mengirim input pengguna.
   - **Controller** tidak peduli bagaimana data digambar di layar. Controller hanya menerima request data mentah (JSON), memproses aturan logika (seperti memastikan tanggal sudah diisi dan status harus `PENDING`), lalu merespons dengan JSON terstruktur.
   - **Model** murni memetakan data ke entitas penyimpanan dan tidak mengurus logika HTTP routing atau rendering UI.

2. **Sinkronisasi Otomatis Absensi (State Update)**:
   - Ketika Admin menyetujui izin (`ApproveLeave` pada controller), backend secara otomatis melakukan operasi *upsert* pada model `Attendance` harian karyawan tersebut untuk mengubah statusnya menjadi `LEAVE` atau `SICK`. Ini memicu update otomatis di View dashboard absensi karyawan.

3. **Soft-Delete Multi-Pihak**:
   - Untuk mencegah data hilang dari salah satu pihak secara sepihak, Model menyediakan field `IsDeletedByEmployee` dan `IsDeletedByAdmin`. Data hanya akan benar-benar terhapus secara fisik (`DB.Delete`) apabila kedua bendera bernilai `true`.
