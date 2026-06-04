import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../common/widgets/app_text_field.dart';

class AdminWifiManagementScreen extends StatefulWidget {
  const AdminWifiManagementScreen({super.key});

  @override
  State<AdminWifiManagementScreen> createState() => _AdminWifiManagementScreenState();
}

class _AdminWifiManagementScreenState extends State<AdminWifiManagementScreen> {
  List<dynamic> _wifis = [];
  List<dynamic> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final resWifis = await ApiClient.get('/api/admin/wifis');
      final resLocations = await ApiClient.get('/api/admin/locations');
      if (mounted) {
        setState(() {
          if (resWifis.success) {
            _wifis = resWifis.data as List<dynamic>? ?? [];
          }
          if (resLocations.success) {
            _locations = resLocations.data as List<dynamic>? ?? [];
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showWifiForm({Map<String, dynamic>? wifi}) {
    final nameCtrl = TextEditingController(text: wifi?['name'] ?? '');
    final bssidCtrl = TextEditingController(text: wifi?['bssid'] ?? '');
    String? selectedLocationId = wifi?['location_id'];
    if (selectedLocationId != null && !_locations.any((l) => l['id'] == selectedLocationId)) {
      selectedLocationId = null;
    }
    bool isActive = wifi?['is_active'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      wifi == null ? 'Tambah Wi-Fi Baru' : 'Edit Wi-Fi Resmi',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Wi-Fi Name field
                AppTextField(
                  controller: nameCtrl,
                  label: 'Nama Wi-Fi (SSID)',
                  prefixIcon: Icons.wifi_rounded,
                ),
                const SizedBox(height: 16),

                // BSSID field
                AppTextField(
                  controller: bssidCtrl,
                  label: 'Alamat MAC Router (BSSID)',
                  prefixIcon: Icons.settings_ethernet_rounded,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-F0-9:-]')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Format BSSID wajib: AA:BB:CC:DD:EE:FF (MAC Address router)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),

                // Dropdown for linking locations
                const Text(
                  'Tautkan ke Lokasi Kantor (Opsional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: selectedLocationId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      hint: const Text('Pilih Lokasi Kantor'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Lokasi / Global'),
                        ),
                        ..._locations.map((loc) {
                          return DropdownMenuItem<String>(
                            value: loc['id']?.toString(),
                            child: Text(loc['name'] ?? ''),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedLocationId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Switch
                SwitchListTile(
                  title: const Text(
                    'Status Jaringan Aktif',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  subtitle: Text(
                    'Aktifkan agar Wi-Fi ini diperbolehkan untuk absensi karyawan',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  value: isActive,
                  activeColor: const Color(0xFF2563EB),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() => isActive = val);
                  },
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final bssid = bssidCtrl.text.trim().toLowerCase();

                      if (name.isEmpty) {
                        AppDialog.showError(ctx, 'Nama Wi-Fi (SSID) wajib diisi');
                        return;
                      }
                      if (bssid.isEmpty) {
                        AppDialog.showError(ctx, 'Alamat MAC Router (BSSID) wajib diisi');
                        return;
                      }

                      final bssidPattern = RegExp(r'^([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})$');
                      if (!bssidPattern.hasMatch(bssid)) {
                        AppDialog.showError(ctx, 'Format MAC Address (BSSID) tidak valid. Contoh: AA:BB:CC:DD:EE:FF');
                        return;
                      }

                      Navigator.pop(ctx);
                      final data = {
                        'name': name,
                        'bssid': bssid,
                        'location_id': selectedLocationId,
                        'is_active': isActive,
                      };

                      bool success;
                      if (wifi == null) {
                        final res = await ApiClient.post('/api/admin/wifis', data);
                        success = res.success;
                      } else {
                        final res = await ApiClient.put('/api/admin/wifis/${wifi['id']}', data);
                        success = res.success;
                      }

                      if (mounted) {
                        if (success) {
                          AppDialog.showSuccess(context, 'Jaringan Wi-Fi berhasil disimpan');
                          _fetchData();
                        } else {
                          AppDialog.showError(context, 'Gagal menyimpan Jaringan Wi-Fi');
                        }
                      }
                    },
                    child: const Text(
                      'Simpan Konfigurasi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteWifi(dynamic wifi) async {
    final ok = await AppDialog.showConfirm(
      context,
      title: 'Hapus Wi-Fi Resmi',
      message: 'Apakah Anda yakin ingin menghapus jaringan Wi-Fi "${wifi['name']}"?',
    );
    if (ok != true) return;

    final res = await ApiClient.delete('/api/admin/wifis/${wifi['id']}');
    if (mounted) {
      if (res.success) {
        AppDialog.showSuccess(context, 'Jaringan Wi-Fi berhasil dihapus');
        _fetchData();
      } else {
        AppDialog.showError(context, 'Gagal menghapus Jaringan Wi-Fi');
      }
    }
  }

  String _getLocationName(String? locationId) {
    if (locationId == null || locationId.isEmpty) return 'Global / Semua Lokasi';
    final loc = _locations.firstWhere((l) => l['id'] == locationId, orElse: () => null);
    return loc != null ? (loc['name'] ?? 'Lokasi Terhapus') : 'Global';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'Manajemen Wi-Fi Kantor',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: _wifis.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada jaringan Wi-Fi terdaftar',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(height: 8),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      'Jika tidak ada Wi-Fi terdaftar, sistem akan memvalidasi geofencing GPS karyawan secara default.',
                                      style: TextStyle(color: Colors.grey, fontSize: 11),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _showWifiForm(),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Daftarkan Wi-Fi Pertama'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _wifis.length,
                              itemBuilder: (ctx, idx) {
                                final wifi = _wifis[idx];
                                final isWifiActive = wifi['is_active'] ?? true;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: (isWifiActive ? const Color(0xFF2563EB) : Colors.grey)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.wifi_rounded,
                                          color: isWifiActive ? const Color(0xFF2563EB) : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    wifi['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isWifiActive
                                                        ? Colors.green.shade50
                                                        : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isWifiActive ? 'Aktif' : 'Nonaktif',
                                                    style: TextStyle(
                                                      color: isWifiActive ? Colors.green : Colors.grey,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'BSSID: ${(wifi['bssid'] ?? '').toString().toUpperCase()}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Lokasi: ${_getLocationName(wifi['location_id'])}',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                        onPressed: () => _showWifiForm(wifi: wifi),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                        onPressed: () => _deleteWifi(wifi),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showWifiForm(),
          backgroundColor: const Color(0xFF2563EB),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Tambah Wi-Fi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
