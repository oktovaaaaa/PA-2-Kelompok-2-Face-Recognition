import 'package:flutter/material.dart';
import '../network/api_client.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // [NEW] Hitung pengajuan izin baru untuk Admin
  int get leaveRequestCount => _notifications
      .where((n) => !n['is_read'] && n['type'] == 'LEAVE_REQUEST')
      .length;

  // [NEW] Hitung status izin (disetujui/ditolak) untuk Karyawan
  int get leaveStatusCount => _notifications
      .where((n) => !n['is_read'] && (n['type'] == 'LEAVE_APPROVED' || n['type'] == 'LEAVE_REJECTED'))
      .length;

  // [NEW] Hitung notifikasi gaji baru untuk Karyawan
  int get salaryCount => _notifications
      .where((n) => !n['is_read'] && n['type'] == 'PAYROLL_PAID')
      .length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get('/api/notifications');
      if (res.success) {
        _notifications = res.data['notifications'] ?? [];
        _unreadCount = (res.data['unread_count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final res = await ApiClient.put('/api/notifications/$id/read', {});
      if (res.success) {
        // Optimistic update
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1 && !_notifications[index]['is_read']) {
          _notifications[index]['is_read'] = true;
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final res = await ApiClient.put('/api/notifications/read-all', {});
      if (res.success) {
        for (var n in _notifications) {
          n['is_read'] = true;
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (_) {}
  }
}
