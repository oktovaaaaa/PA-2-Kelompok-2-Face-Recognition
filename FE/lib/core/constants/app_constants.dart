class AppConstants {
  // Public HTTPS URL Server Kampus (Cloudflare Tunnel - 100% Publik Tanpa Izin Browser):
  static const String baseUrl = 'https://raise-glucose-quarter-enzyme.trycloudflare.com';

  // Tailscale Funnel:
  // static const String baseUrl = 'https://tati-glory.tail10defd.ts.net';

  // Koneksi Lokal Kampus (WiFi yang sama):
  // static const String baseUrl = 'http://172.22.44.26:8080';

  // Emulator Android (Koneksi ke backend lokal di laptop):
  // static const String baseUrl = 'http://10.0.2.2:8080';

  // HP fisik (koneksi USB dengan 'adb reverse tcp:8080 tcp:8080'):
  // static const String baseUrl = 'http://localhost:8080';

  // HP fisik (koneksi Wi-Fi yang sama):
  // static const String baseUrl = 'http://172.27.66.12:8080';

  // HP fisik: ganti dengan IP laptop (IP saat ini: 172.27.66.12)
  // static const String baseUrl = 'http://localhost:8080';

  static const String appName = 'Videnti';
}
