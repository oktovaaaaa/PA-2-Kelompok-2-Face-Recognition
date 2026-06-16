// lib/core/providers/session_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_provider.dart';

class SessionProvider extends ChangeNotifier {
  Timer? _inactivityTimer;
  final AuthProvider authProvider;
  DateTime? _lastActiveTime;

  SessionProvider({required this.authProvider}) {
    // Listen to AuthProvider changes – when user logs in, start the timer automatically
    authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (authProvider.isAuthenticated && !authProvider.isSessionLocked) {
      startTimer();
    } else {
      _cancelTimer();
    }
  }

  void startTimer() {
    _cancelTimer();
    if (!authProvider.isAuthenticated) return; 

    // Update last activity time but Don't start an inactivity timer for foreground use
    // to strictly follow user request (lock only when backgrounded).
    _lastActiveTime = DateTime.now();
  }

  void resetTimer() {
    if (authProvider.isAuthenticated && !authProvider.isSessionLocked) {
      startTimer();
    }
  }

  void _cancelTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  bool _isInForeground = true;

  void handleAppLifecycleState(AppLifecycleState state) {
    print("DEBUG: Lifecycle State Changed to: $state");
    // abaikan perubahan status jika user belum login
    if (!authProvider.isAuthenticated) {
      print("DEBUG: User not authenticated, ignoring lifecycle change.");
      return;
    }

    // jika aplikasi ditinggalkan (ke background / tidak aktif)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isInForeground) {
        // catat waktu terakhir aktif saat mulai ditinggalkan
        _lastActiveTime = DateTime.now();
        _isInForeground = false;
        print("DEBUG: App leaving foreground at: $_lastActiveTime");
        _cancelTimer();
      }
    // jika aplikasi dibuka kembali dari background (resumed)
    } else if (state == AppLifecycleState.resumed) {
      print("DEBUG: App resumed. Previous foreground state: $_isInForeground");
      if (!_isInForeground) {
        _isInForeground = true;
        if (_lastActiveTime != null) {
          // hitung selisih waktu selama aplikasi ditinggalkan di background
          final diff = DateTime.now().difference(_lastActiveTime!);
          print("DEBUG: Time spent in background: ${diff.inSeconds} seconds");
          // jika ditinggalkan selama 15 menit atau lebih, kunci sesi dan minta pin/biometrik
          if (diff.inMinutes >= 15) {
            print("DEBUG: Lock threshold (15m) reached. Locking session...");
            authProvider.lockSession();
          } else {
            print("DEBUG: Lock threshold not reached. Resuming session.");
            startTimer();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    _cancelTimer();
    super.dispose();
  }
}
