// lib/features/employee/presentation/screens/tabs/employee_salary_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/network/api_client.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/date_formatter.dart';

class EmployeeSalaryTab extends StatefulWidget {
  const EmployeeSalaryTab({super.key});

  @override
  State<EmployeeSalaryTab> createState() => _EmployeeSalaryTabState();
}

class _EmployeeSalaryTabState extends State<EmployeeSalaryTab> {
  List<dynamic> _salaries = [];
  List<int> _availableYears = [DateTime.now().year];
  bool _loading = false;
  bool _loadingYears = false;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<String> _months = [
    'Semua Bulan', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableYears().then((_) {
      _loadSalaries();
    });
  }

  Future<void> _loadAvailableYears() async {
    setState(() => _loadingYears = true);
    try {
      final res = await ApiClient.get('/api/employee/salaries/years');
      if (res.success && mounted) {
        final List<int> years = List<int>.from(res.data ?? []);
        setState(() {
          _availableYears = years;
          // Jika tahun sekarang tidak ada datanya, pilih tahun terbaru yang ada
          if (_availableYears.isNotEmpty && !_availableYears.contains(_selectedYear)) {
            _selectedYear = _availableYears.first;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loadingYears = false);
    }
  }

  Future<void> _loadSalaries() async {
    setState(() => _loading = true);
    try {
      String url = '/api/employee/salaries?year=$_selectedYear';
      if (_selectedMonth != 0) {
        url += '&month=$_selectedMonth';
      }
      final res = await ApiClient.get(url);
      if (res.success && mounted) {
        setState(() => _salaries = res.data ?? []);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat.decimalPattern('id').format(amount)}';
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month < 1 || month > 12) return '-';
    return months[month - 1];
  }

  void _showSalaryDetail(Map<String, dynamic> salary) {
    final payments = salary['payments'] as List<dynamic>? ?? [];
    final details = salary['deductions_detail'] as String? ?? '';
    final total = (salary['total_salary'] as num).toDouble();
    final paid = (salary['paid_amount'] as num? ?? 0).toDouble();
    final balance = total - paid;
    final status = salary['status'];
    final isPaid = status == 'PAID';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gaji ${_getMonthName(salary['month'] ?? 0)} ${salary['year']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text('Rincian penghasilan & riwayat transfer', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPaid ? Colors.green : (paid > 0 ? Colors.blue : Colors.orange)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'LUNAS' : (paid > 0 ? 'DICICIL' : 'MENUNGGU'),
                      style: TextStyle(
                        color: isPaid ? Colors.green : (paid > 0 ? Colors.blue : Colors.orange), 
                        fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),

              // Summary Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  children: [
                    _buildDetailRow('Besar Gaji (Netto)', _formatCurrency(total), isBold: true),
                    const SizedBox(height: 8),
                    _buildDetailRow('Sudah Diterima', _formatCurrency(paid), color: Colors.green),
                    if (!isPaid) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Sisa Saldo', _formatCurrency(balance), color: const Color(0xFF1E3A8A), isBold: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment History Section
              const Text('Riwayat Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              if (payments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text('Belum ada transaksi transfer', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    final date = DateTime.parse(p['paid_at'] ?? DateTime.now().toString());
                    final amount = (p['amount'] as num).toDouble();
                    final proof = p['proof'] as String?;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(AppDateFormatter.formatFullDate(p['paid_at'] ?? ''), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                          ),
                          if (proof != null && proof.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _showProofImage(AppConstants.baseUrl + proof),
                              icon: const Icon(Icons.image_outlined, size: 16),
                              label: const Text('Bukti', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1E3A8A),
                                backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.05),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 32),

              // Deductions Section
              const Text('Rincian Pelanggaran & Denda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              if (details.isEmpty)
                 Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Text('Tidak ada pelanggaran periode ini', style: TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                Column(
                  children: details.split('; ').where((s) => s.isNotEmpty).map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 12),
                        Expanded(child: Text(AppDateFormatter.formatInString(item), style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)))),
                      ],
                    ),
                  )).toList(),
                ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 32)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(
          fontSize: isBold ? 15 : 14, 
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: color ?? const Color(0xFF0F172A),
        )),
      ],
    );
  }

  void _showYearPicker(BuildContext context) {
    if (_availableYears.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 12),
                Text('Pilih Tahun Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Hanya menampilkan tahun yang memiliki data riwayat gaji', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const Divider(height: 32),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _availableYears.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final year = _availableYears[index];
                  final isSelected = _selectedYear == year;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedYear = year);
                      _loadSalaries();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF1E3A8A), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 32),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Gaji',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rekapitulasi penghasilan bulanan Anda',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Month & Year Pickers (Premium White)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                              items: [
                                for (int i = 0; i <= 12; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                      _months[i],
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedMonth = v);
                                  _loadSalaries();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                              items: [
                                if (_availableYears.isEmpty)
                                  DropdownMenuItem(value: _selectedYear, child: Text(_selectedYear.toString()))
                                else
                                  for (int y in _availableYears)
                                    DropdownMenuItem(
                                      value: y,
                                      child: Text(y.toString(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedYear = v);
                                  _loadSalaries();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _salaries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Belum ada data gaji', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSalaries,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                            itemCount: _salaries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (_, i) {
                                final s = _salaries[i] as Map<String, dynamic>;
                                final status = s['status'];
                                final isPaid = status == 'PAID';
                                final isPartial = status == 'PARTIAL';
                                
                                final total = (s['total_salary'] as num).toDouble();
                                final paid = (s['paid_amount'] as num? ?? 0).toDouble();
                                final base = (s['base_salary'] as num).toDouble();
                                final deductions = (s['deductions'] as num).toDouble();
                                final balance = total - paid;

                                return InkWell(
                                  onTap: () => _showSalaryDetail(s),
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isPaid 
                                          ? [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF34D399)] 
                                          : (isPartial 
                                              ? [const Color(0xFF1E40AF), const Color(0xFF2563EB), const Color(0xFF3B82F6)]
                                              : [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF334155)]),
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isPaid ? const Color(0xFF10B981) : const Color(0xFF2563EB)).withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          right: -20,
                                          bottom: -20,
                                          child: Icon(
                                            isPaid ? Icons.check_circle_outline_rounded : Icons.payments_outlined,
                                            size: 120,
                                            color: Colors.white.withOpacity(0.08),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Periode ${_getMonthName(s['month'] ?? 0)} ${s['year']}',
                                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      isPaid ? 'LUNAS' : (isPartial ? 'DICICIL' : 'MENUNGGU'),
                                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                _formatCurrency(total),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              Text(
                                                'Total Hak Gaji (Netto)',
                                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                                              ),
                                              
                                              const SizedBox(height: 24),
                                              
                                              // Rincian Pembayaran Box
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text('Sudah Diterima', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                                        Text(_formatCurrency(paid), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                      ],
                                                    ),
                                                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.white10)),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text('Sisa Pembayaran', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                                        Text(
                                                          balance <= 0 ? 'Lunas' : _formatCurrency(balance), 
                                                          style: TextStyle(
                                                            color: balance <= 0 ? Colors.greenAccent : Colors.orangeAccent, 
                                                            fontWeight: FontWeight.bold, 
                                                            fontSize: 14
                                                          )
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              const SizedBox(height: 24),
                                              
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Gaji Pokok', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                                                        Text(_formatCurrency(base), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text('Potongan', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                                                        Text('- ${_formatCurrency(deductions)}', style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white10)),
                                              
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(isPaid ? Icons.verified_rounded : (isPartial ? Icons.hourglass_bottom_rounded : Icons.info_outline_rounded), 
                                                           color: Colors.white, size: 18),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        isPaid ? 'Pembayaran Selesai' : (isPartial ? 'Dicicil (Sisa: ${_formatCurrency(balance)})' : 'Menunggu Transfer'),
                                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
}
