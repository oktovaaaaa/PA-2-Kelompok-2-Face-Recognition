// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../../common/widgets/premium_bottom_nav.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_leave_tab.dart';
import 'admin_payroll_screen.dart';
import 'tabs/admin_employee_tab.dart';
import 'tabs/admin_profile_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const AdminDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late int _currentIndex;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabs = [
      AdminHomeTab(onNavigate: (i) => setState(() => _currentIndex = i)),
      const AdminLeaveTab(),
      const AdminPayrollScreen(isTab: true),
      const AdminEmployeeTab(),
      const AdminProfileTab(),
    ];
  }

  Future<void> _logout() async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
    final user = context.watch<AuthProvider>().currentUser;
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String role = (user['role'] ?? '').toString().toUpperCase();
    if (role != 'ADMIN' && role != 'OWNER' && role != 'SUPER_ADMIN') {
      return const Scaffold(body: Center(child: Text('Akses Ditolak: Hanya Admin')));
    }

    final icons = [
      Icons.home_rounded,
      Icons.assignment_rounded,
      Icons.work_rounded,
      Icons.people_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Hide standard appBar, custom header will be in each tab
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      extendBody: false,
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavItem(icon: Icons.home_rounded, label: 'Beranda'),
          BottomNavItem(icon: Icons.assignment_rounded, label: 'Perizinan'),
          BottomNavItem(icon: Icons.payments_rounded, label: 'Gaji'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Karyawan'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
        ],
      ),
    );
  }
}