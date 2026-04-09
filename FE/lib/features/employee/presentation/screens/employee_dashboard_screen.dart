// lib/features/employee/presentation/screens/employee_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../../common/widgets/premium_bottom_nav.dart';
import 'tabs/employee_attendance_tab.dart';
import 'tabs/employee_history_tab.dart';
import 'tabs/employee_leave_tab.dart';
import 'tabs/employee_profile_tab.dart';
import 'tabs/employee_salary_tab.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const EmployeeDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late int _currentIndex;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabs = [
      EmployeeAttendanceTab(onNavigate: (i) => setState(() => _currentIndex = i)),
      const EmployeeHistoryTab(),
      const EmployeeLeaveTab(),
      const EmployeeSalaryTab(),
      const EmployeeProfileTab(),
    ];
  }

  Future<void> _logout() async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (act != true) return;
    await SessionStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: false,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavItem(icon: Icons.account_balance_wallet_rounded, label: 'Beranda'),
          BottomNavItem(icon: Icons.receipt_long_rounded, label: 'Riwayat'),
          BottomNavItem(icon: Icons.assignment_turned_in_rounded, label: 'Izin'),
          BottomNavItem(icon: Icons.payments_rounded, label: 'Gaji'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
        ],
      ),
    );
  }
}
