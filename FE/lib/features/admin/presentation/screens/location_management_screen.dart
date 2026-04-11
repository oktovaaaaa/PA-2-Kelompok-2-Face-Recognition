import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../common/widgets/app_text_field.dart';

class AdminLocationManagementScreen extends StatefulWidget {
  const AdminLocationManagementScreen({super.key});

  @override
  State<AdminLocationManagementScreen> createState() => _AdminLocationManagementScreenState();
}

class _AdminLocationManagementScreenState extends State<AdminLocationManagementScreen> {
  List<dynamic> _locations = [];
  bool _loading = true;
  final MapController _mapController = MapController();
  
  // Search Autocomplete State
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/admin/locations');
      if (res.success) {
        setState(() => _locations = res.data as List<dynamic>);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchAddress(String query, {VoidCallback? onUpdate, StateSetter? setDialogState}) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() => _suggestions = []);
        if (setDialogState != null) setDialogState(() {});
        if (onUpdate != null) onUpdate();
      }
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        setState(() => _isSearching = true);
        if (setDialogState != null) setDialogState(() {});
        if (onUpdate != null) onUpdate();
      }
      
      try {
        final res = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query&addressdetails=1&limit=5'),
          headers: {
            'User-Agent': 'VidentiAttendanceApp/1.0 (com.videnti.app)',
            'Accept-Language': 'id', // Prioritaskan hasil dalam Bahasa Indonesia
          },
        );
        
        if (res.statusCode == 200) {
          if (mounted) {
            setState(() => _suggestions = jsonDecode(res.body));
            if (setDialogState != null) setDialogState(() {});
          }
        } else {
          debugPrint('Nominatim Error: ${res.statusCode} - ${res.body}');
          if (mounted) {
            setState(() => _suggestions = []);
            if (setDialogState != null) setDialogState(() {});
          }
        }
      } catch (e) {
        debugPrint('Search API Exception: $e');
        if (mounted) {
          setState(() => _suggestions = []);
          if (setDialogState != null) setDialogState(() {});
        }
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
          if (setDialogState != null) setDialogState(() {});
          if (onUpdate != null) onUpdate();
        }
      }
    });
  }

  void _showLocationForm({Map<String, dynamic>? location}) async {
    final nameCtrl = TextEditingController(text: location?['name'] ?? '');
    final radiusCtrl = TextEditingController(text: location?['radius']?.toString() ?? '100');
    
    LatLng selectedPos;
    if (location != null) {
      selectedPos = LatLng((location['latitude'] as num).toDouble(), (location['longitude'] as num).toDouble());
    } else {
      // Default to GPS or Jakarta
      setState(() => _loading = true);
      try {
        final pos = await Geolocator.getCurrentPosition();
        selectedPos = LatLng(pos.latitude, pos.longitude);
      } catch (e) {
        selectedPos = const LatLng(-6.2088, 106.8456); // Jakarta
      }
      setState(() => _loading = false);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location == null ? 'Tambah Lokasi Baru' : 'Edit Lokasi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(controller: nameCtrl, label: 'Nama Lokasi', prefixIcon: Icons.business_rounded),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: radiusCtrl, 
                    label: 'Radius Absensi (Meter)', 
                    prefixIcon: Icons.radar_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Lokasi di Peta (Tap untuk memindah pin)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                                     // Search Bar inside Dialog
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari Alamat di Sini...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 22),
                          suffixIcon: _searchCtrl.text.isNotEmpty 
                            ? (_isSearching 
                                ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                                : IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () {
                                    _searchCtrl.clear();
                                    _searchAddress('', setDialogState: setDialogState);
                                  }))
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) {
                          _searchAddress(v, setDialogState: setDialogState);
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: selectedPos,
                              initialZoom: 16.0,
                              onTap: (_, p) => setDialogState(() => selectedPos = p),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.videnti.app',
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: selectedPos,
                                    radius: double.tryParse(radiusCtrl.text) ?? 100,
                                    useRadiusInMeter: true,
                                    color: const Color(0xFF2563EB).withOpacity(0.2),
                                    borderStrokeWidth: 2,
                                    borderColor: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: selectedPos,
                                    width: 44,
                                    height: 44,
                                    child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 44),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Floating Search Suggestions
                        if (_suggestions.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              color: Colors.white,
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 220),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                  itemBuilder: (ctx, idx) {
                                    final s = _suggestions[idx];
                                    return ListTile(
                                      visualDensity: VisualDensity.compact,
                                      leading: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF2563EB)),
                                      title: Text(
                                        s['display_name'], 
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)), 
                                        maxLines: 2, 
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      subtitle: s['type'] != null ? Text(s['type'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 0.5)) : null,
                                      onTap: () {
                                        final lat = double.parse(s['lat']);
                                        final lon = double.parse(s['lon']);
                                        setDialogState(() {
                                          selectedPos = LatLng(lat, lon);
                                          _mapController.move(selectedPos, 16.0);
                                          _searchCtrl.clear();
                                          _suggestions = [];
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        // Zoom Controls
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Column(
                            children: [
                              _buildMapAction(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildMapAction(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              AppDialog.showError(ctx, 'Nama lokasi wajib diisi');
                              return;
                            }
                            Navigator.pop(ctx);
                            final data = {
                              'name': nameCtrl.text,
                              'latitude': selectedPos.latitude,
                              'longitude': selectedPos.longitude,
                              'radius': int.tryParse(radiusCtrl.text) ?? 100,
                            };

                            bool success;
                            if (location == null) {
                              final res = await ApiClient.post('/api/admin/locations', data);
                              success = res.success;
                            } else {
                              final res = await ApiClient.put('/api/admin/locations/${location['id']}', data);
                              success = res.success;
                            }

                            if (mounted) {
                              if (success) {
                                AppDialog.showSuccess(context, 'Berhasil menyimpan lokasi');
                                _fetchLocations();
                              } else {
                                AppDialog.showError(context, 'Gagal menyimpan lokasi');
                              }
                            }
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLocation(dynamic loc) async {
    final ok = await AppDialog.showConfirm(
      context,
      title: 'Hapus Lokasi',
      message: 'Apakah Anda yakin ingin menghapus "${loc['name']}"?',
    );
    if (ok != true) return;

    final res = await ApiClient.delete('/api/admin/locations/${loc['id']}');
    if (mounted) {
      if (res.success) {
        AppDialog.showSuccess(context, 'Lokasi berhasil dihapus');
        _fetchLocations();
      } else {
        AppDialog.showError(context, 'Gagal menghapus lokasi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manajemen Lokasi Kantor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: _fetchLocations,
              child: _locations.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Belum ada lokasi kantor', style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showLocationForm(), 
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah Lokasi Pertama'),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _locations.length,
                      itemBuilder: (ctx, idx) {
                        final loc = _locations[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(loc['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Radius: ${loc['radius']} meter', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('Koordinat: ${loc['latitude']}, ${loc['longitude']}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                onPressed: () => _showLocationForm(location: loc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                onPressed: () => _deleteLocation(loc),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationForm(),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Tambah Lokasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMapAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
      ),
    );
  }
}
