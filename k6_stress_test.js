/**
 * k6 Stress Test Script - Sistem Absensi Videnti (Employee Endpoints)
 * Target: http://103.49.238.222:8080
 *
 * cara jalankan stress test k6:
 *   1. pastikan k6 sudah terinstall di perangkat (download dari k6.io atau via brew/choco)
 *   2. buat file 'face_base64.txt' di direktori yang sama berisi string base64 gambar wajah untuk pengetesan face recognition
 *   3. jalankan perintah dasar berikut di terminal:
 *        k6 run k6_stress_test.js
 *   4. jika ingin mengekspor hasil statistik pengetesan ke file csv, jalankan:
 *        k6 run --out csv=results.csv k6_stress_test.js
 */

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';


// KONFIGURASI TARGET
const BASE_URL = 'http://103.49.238.222:8080';

// Token Karyawan
const EMPLOYEE_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55X2lkIjoiODQ1MzAyNmItYmE5ZS00MWFlLTlkNDktMWRhYjI0ZGJmMDA2IiwiZXhwIjoxNzgyNDQwMzQ3LCJyb2xlIjoiRU1QTE9ZRUUiLCJ1c2VyX2lkIjoiOTcwNWRiNjUtMWM4NC00MDBjLWFhOTYtOTJjOTcxOWFhMjhkIn0.RVUx2yN-3Dz6CZvm-9pLd5-Cgw4ubs0k0xHqZidYnZQ';

// Load face image dari file (k6 baca saat startup)
const FACE_IMAGE = open('./face_base64.txt');

// ==========================================
// SKENARIO STRESS TEST
// ==========================================
export const options = {
  scenarios: {
    stress_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 10 },   // Naik ke 10 user
        { duration: '1m',  target: 50 },   // Naik ke 50 user
        { duration: '1m',  target: 100 },  // Naik ke 100 user
        { duration: '30s', target: 100 },  // Tahan 100 user
        { duration: '30s', target: 0 },    // Cool down
      ],
    },
  },

  thresholds: {
    http_req_duration: ['p(95)<5000'],  // 95% request < 5 detik
    http_req_failed:   ['rate<0.20'],   // Error rate < 20%
  },
};

// ==========================================
// CUSTOM METRICS
// ==========================================
const checkinDuration = new Trend('checkin_response_time');
const checkinFailRate = new Rate('checkin_fail_rate');

// ==========================================
// HEADERS
// ==========================================
const employeeHeaders = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${EMPLOYEE_TOKEN}`,
};

// ==========================================
// SKENARIO UTAMA
// ==========================================
export default function () {

  // ----- TEST 1: GET Profil Karyawan -----
  group('Employee - Get Profile', () => {
    const res = http.get(`${BASE_URL}/api/profile`, { headers: employeeHeaders });

    check(res, {
      'GET profile: status 200': (r) => r.status === 200,
      'GET profile: response time < 3s': (r) => r.timings.duration < 3000,
    });

    sleep(0.5);
  });

  // ----- TEST 2: GET Absensi Hari Ini -----
  group('Employee - Get Today Attendance', () => {
    const res = http.get(`${BASE_URL}/api/employee/attendance/today`, { headers: employeeHeaders });

    check(res, {
      'GET today: status OK': (r) => r.status === 200 || r.status === 404,
      'GET today: response time < 3s': (r) => r.timings.duration < 3000,
    });

    sleep(0.5);
  });

  // ----- TEST 3: GET Riwayat Absensi -----
  group('Employee - Get Attendance History', () => {
    const res = http.get(`${BASE_URL}/api/employee/attendance/history`, { headers: employeeHeaders });

    check(res, {
      'GET history: status 200': (r) => r.status === 200,
      'GET history: response time < 3s': (r) => r.timings.duration < 3000,
    });

    sleep(0.5);
  });

  // ----- TEST 4: POST Check-In dengan Face Recognition -----
  // Catatan: Server tetap memproses face recognition untuk SEMUA request
  // meski hanya 1 yang berhasil (sisanya dapat "sudah absen" - ini normal!)
  // Yang ditest: apakah server tahan menjalankan face recognition 100x bersamaan
  group('Employee - Check In (Face Recognition Load Test)', () => {
    const payload = JSON.stringify({
      latitude:   2.3856999379272374,   // Koordinat Camp Nou, Barcelona
      longitude:  99.1478135628844,  // Koordinat Camp Nou, Barcelona
      face_image: FACE_IMAGE.trim(),  // Face image asli dari file
      bssid: '',
      ssid: '',
    });

    const res = http.post(`${BASE_URL}/api/employee/attendance/checkin`, payload, { headers: employeeHeaders });

    const body = JSON.parse(res.body);

    check(res, {
      // Server dianggap OK jika:
      // 200 = check-in berhasil
      // 400 = sudah absen / di luar radius / wajah tidak cocok (logika bisnis, bukan error server)
      // Yang TIDAK OK: 500 = server crash
      'POST checkin: server tidak crash (bukan 5xx)': (r) => r.status < 500,
      'POST checkin: merespons < 10 detik': (r) => r.timings.duration < 10000,
    });

    // Log hasil untuk analisis
    if (res.status === 200) {
      console.log(`[OK] VU ${__VU}: Check-in BERHASIL`);
    } else if (res.status === 400) {
      // Normal - "sudah absen" / geofence / face tidak cocok
      // Face recognition TETAP diproses sebelum error ini!
    } else if (res.status >= 500) {
      console.log(`[SERVER ERROR] VU ${__VU}: Status ${res.status} | ${res.body.substring(0, 150)}`);
    }

    checkinDuration.add(res.timings.duration);
    checkinFailRate.add(res.status >= 500 ? 1 : 0);

    sleep(1);
  });

  // ----- TEST 5: GET Daftar Izin -----
  group('Employee - Get Leaves', () => {
    const res = http.get(`${BASE_URL}/api/employee/leaves`, { headers: employeeHeaders });

    check(res, {
      'GET leaves: status 200': (r) => r.status === 200,
      'GET leaves: response time < 3s': (r) => r.timings.duration < 3000,
    });

    sleep(0.5);
  });

  // ----- TEST 6: GET Lokasi Perusahaan -----
  group('Employee - Get Locations', () => {
    const res = http.get(`${BASE_URL}/api/employee/locations`, { headers: employeeHeaders });

    check(res, {
      'GET locations: status 200': (r) => r.status === 200,
    });

    sleep(0.5);
  });

  sleep(1);
}
