import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/screens/pending_employees_screen.dart';
import '../../../admin/presentation/screens/admin_payroll_screen.dart';
import '../../../employee/presentation/screens/employee_dashboard_screen.dart';
import '../../../../core/providers/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Premium Curved Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 28),
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
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Notifikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                  tooltip: 'Tandai semua dibaca',
                  onPressed: () => _confirmMarkAll(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                }

                if (provider.notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  onRefresh: () => provider.fetchNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = provider.notifications[index];
                      return _buildNotifItem(context, provider, notif);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi Anda akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, NotificationProvider provider, dynamic notif) {
    final bool isRead = notif['is_read'] ?? false;
    final String type = notif['type'] ?? 'DEFAULT';
    final DateTime createdAt = DateTime.parse(notif['created_at']);
    final String timeStr = AppDateFormatter.formatFullDate(notif['created_at']);

    IconData icon;
    Color color;

    switch (type) {
      case 'LEAVE_REQUEST':
        icon = Icons.assignment_late_rounded;
        color = const Color(0xFFD97706);
        break;
      case 'LEAVE_APPROVED':
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'LEAVE_REJECTED':
      case 'PENALTY_RECEIVED':
        icon = Icons.cancel_rounded;
        color = const Color(0xFFEF4444);
        break;
      case 'PAYROLL_PAID':
      case 'BONUS_RECEIVED':
        icon = Icons.payments_rounded;
        color = const Color(0xFF2563EB);
        break;
      case 'POSITION_UPDATE':
        icon = Icons.work_history_rounded;
        color = const Color(0xFF4F46E5);
        break;
      default:
        icon = Icons.notifications_rounded;
        color = const Color(0xFF64748B);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          provider.markAsRead(notif['id']);
        }
        
        switch (type) {
          case 'EMPLOYEE_REGISTERED':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingEmployeesScreen()));
            break;
          case 'PAYROLL_PAID':
          case 'BONUS_RECEIVED':
          case 'PENALTY_RECEIVED':
            final role = context.read<AuthProvider>().currentUser?['role'];
            if (role == 'ADMIN') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPayrollScreen()));
            } else {
              // Navigate to Employee Dashboard at Salary Tab (Index 3)
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen(initialIndex: 3)),
                (route) => false
              );
            }
            break;
          case 'LEAVE_REQUEST':
          case 'LEAVE_APPROVED':
          case 'LEAVE_REJECTED':
            final role = context.read<AuthProvider>().currentUser?['role'];
            if (role == 'ADMIN') {
              // Admin leaves are managed on web, but if they are on mobile, just pop
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen(initialIndex: 2)),
                (route) => false
              );
            }
            break;
          default:
            // Just mark as read
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFF2563EB).withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? Colors.grey.shade100 : const Color(0xFF2563EB).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 15,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    timeStr,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmMarkAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Semua Dibaca'),
        content: const Text('Apakah Anda yakin ingin menandai semua notifikasi sebagai sudah dibaca?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
              Navigator.pop(ctx);
            },
            child: const Text('Ya, Dibaca', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
