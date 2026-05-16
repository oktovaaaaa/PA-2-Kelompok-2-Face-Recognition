import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../../core/constants/app_constants.dart';

class AdminLeaveTab extends StatefulWidget {
  const AdminLeaveTab({super.key});

  @override
  State<AdminLeaveTab> createState() => _AdminLeaveTabState();
}

class _AdminLeaveTabState extends State<AdminLeaveTab> {
  List<dynamic> _leaves = [];
  bool _loading = false;
  String _selectedStatus = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  final List<int> _years = [2024, 2025, 2026];

  final _statusLabels = {'PENDING': 'Menunggu', 'APPROVED': 'Disetujui', 'REJECTED': 'Ditolak'};
  final _statusColors = {
    'PENDING': Colors.orange,
    'APPROVED': Colors.green,
    'REJECTED': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLeaves() async {
    setState(() => _loading = true);
    try {
      String url = '/api/admin/leaves?month=$_selectedMonth&year=$_selectedYear';
      if (_selectedStatus != 'ALL') url += '&status=$_selectedStatus';
      if (_searchCtrl.text.isNotEmpty) url += '&search=${Uri.encodeComponent(_searchCtrl.text)}';

      final res = await ApiClient.get(url);
      if (res.success && mounted) {
        setState(() => _leaves = res.data ?? []);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processLeave(String id, String action) async {
    final noteCtrl = TextEditingController();
    final actionTitle = action == 'approve' ? 'Setujui Izin' : 'Tolak Izin';
    final actionLabel = action == 'approve' ? 'Setujui' : 'Tolak';
    final actionColor = action == 'approve' ? Colors.green : Colors.red;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(actionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin ${action == 'approve' ? 'menyetujui' : 'menolak'} izin ini?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text('Catatan/Alasan (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis alasan di sini...',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final res = await ApiClient.put('/api/admin/leaves/$id/$action', {'note': noteCtrl.text});
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, action == 'approve' ? 'Izin disetujui' : 'Izin ditolak');
        _loadLeaves();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal memproses izin');
      }
    } catch (_) {}
  }

  void _showDetail(Map<String, dynamic> leave) {
    final status = leave['status'] ?? '';
    final color = _statusColors[status] ?? Colors.grey;
    final isPending = status == 'PENDING';
    final typeIcon = leave['type'] == 'SAKIT' ? Icons.medical_services_rounded : Icons.assignment_rounded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // 1. Header & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Icon(typeIcon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(leave['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                              child: Text(_statusLabels[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. Data Pengaju Card
                  _buildSectionTitle('Informasi Pengaju'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.person_outline_rounded, 'Karyawan', leave['user_name'] ?? '-'),
                    _buildInfoRow(Icons.alternate_email_rounded, 'Email', leave['user_email'] ?? '-'),
                  ]),
                  const SizedBox(height: 24),

                  // 3. Detail Pengajuan Card
                  _buildSectionTitle('Detail Pengajuan'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.category_outlined, 'Tipe Izin', leave['type'] ?? '-'),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal', _formatDates(leave['dates'] ?? '')),
                    _buildInfoRow(Icons.description_outlined, 'Deskripsi', leave['description'] ?? '-', isMultiline: true),
                  ]),
                  const SizedBox(height: 24),

                  // 4. Bukti Foto
                  if (leave['photo_url'] != null && (leave['photo_url'] as String).isNotEmpty) ...[
                    _buildSectionTitle('Bukti Foto'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showFullScreenImage(ctx, AppConstants.baseUrl + leave['photo_url']),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            AppConstants.baseUrl + leave['photo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 5. Catatan Admin
                  if (leave['admin_note'] != null && (leave['admin_note'] as String).isNotEmpty) ...[
                    _buildSectionTitle('Tanggapan Admin'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF475569)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              leave['admin_note'],
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF475569), height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // 5. Action Buttons (If Pending)
                  if (isPending)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () { Navigator.pop(ctx); _processLeave(leave['id'], 'approve'); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () { Navigator.pop(ctx); _processLeave(leave['id'], 'reject'); },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade600, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Tolak', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manajemen Izin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // Filters inside header
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          label: '${_monthName(_selectedMonth)} $_selectedYear',
                          icon: Icons.calendar_today_rounded,
                          onTap: _showMonthYearPicker,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          label: _selectedStatus == 'ALL' ? 'Semua Izin' : (_statusLabels[_selectedStatus] ?? 'Status'),
                          icon: Icons.filter_list_rounded,
                          onTap: _showStatusPicker,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar inside Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => _loadLeaves(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama karyawan...',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _leaves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(
                                  _searchCtrl.text.isEmpty ? Icons.assignment_late_rounded : Icons.search_off_rounded, 
                                  size: 64, 
                                  color: Colors.grey.shade300
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchCtrl.text.isEmpty ? 'Tidak ada data izin' : 'Pencarian tidak ditemukan', 
                                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadLeaves,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            itemCount: _leaves.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final l = _leaves[i] as Map<String, dynamic>;
                              final status = l['status'] ?? '';
                              final color = _statusColors[status] ?? Colors.grey;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _showDetail(l),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              l['type'] == 'SAKIT' ? Icons.sick_rounded : Icons.event_note_rounded,
                                              color: color,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(l['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${l['user_name'] ?? '-'} • ${_formatDates(l['dates'] ?? '')}',
                                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthYearPicker() async {
     await showModalBottomSheet(
       context: context,
       builder: (ctx) => Container(
         padding: const EdgeInsets.all(24),
         height: 300,
         child: Column(
           children: [
             const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const Expanded(child: SizedBox()),
             Row(
               children: [
                 Expanded(
                   child: DropdownButton<int>(
                     isExpanded: true,
                     value: _selectedMonth,
                     items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_monthName(i+1)))),
                     onChanged: (v) { setState(() => _selectedMonth = v!); Navigator.pop(ctx); _loadLeaves(); },
                   ),
                 ),
                 const SizedBox(width: 16),
                  Expanded(
                   child: DropdownButton<int>(
                     isExpanded: true,
                     value: _selectedYear,
                     items: List.generate(5, (i) => DropdownMenuItem(value: DateTime.now().year - i, child: Text('${DateTime.now().year - i}'))),
                     onChanged: (v) { setState(() => _selectedYear = v!); Navigator.pop(ctx); _loadLeaves(); },
                   ),
                 ),
               ],
             ),
             const Expanded(child: SizedBox()),
           ],
         ),
       ),
     );
  }

  void _showStatusPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Semua Izin'),
              onTap: () { setState(() => _selectedStatus = 'ALL'); Navigator.pop(ctx); _loadLeaves(); },
            ),
            ...(_statusLabels.entries.map((e) => ListTile(
              title: Text(e.value),
              onTap: () { setState(() => _selectedStatus = e.key); Navigator.pop(ctx); _loadLeaves(); },
            ))),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  String _formatDates(String datesJson) {
    if (datesJson.isEmpty) return '-';
    try {
      final List<dynamic> dates = jsonDecode(datesJson);
      if (dates.isEmpty) return '-';
      if (dates.length == 1) return DateFormat('dd MMM yyyy').format(DateTime.parse(dates[0]));
      
      final sorted = dates.map((d) => DateTime.parse(d)).toList()..sort();
      final first = sorted.first;
      final last = sorted.last;
      
      bool isContiguous = true;
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i+1].difference(sorted[i]).inDays != 1) {
          isContiguous = false;
          break;
        }
      }
      
      return isContiguous
          ? '${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(first)} - \n${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(last)}\n(${dates.length} Hari)'
          : sorted.map((d) => DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d)).join('\n');
    } catch (_) {
      return '-';
    }
  }

  String _monthName(int m) {
    return ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][m-1];
  }
}
