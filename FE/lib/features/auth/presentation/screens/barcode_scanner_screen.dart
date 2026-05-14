// lib/features/auth/presentation/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/error_mapper.dart';
import '../../data/auth_repository.dart';
import 'register_employee_screen.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/app_dialog.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _repo = AuthRepository();
  final _manualTokenController = TextEditingController();
  bool _loading = false;
  bool _isProcessing = false;

  Future<void> _processToken(String token) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _loading = true;
    });

      try {
        final res = await _repo.validateInvite(token.trim());
        final companyId = (res['company_id'] ?? '').toString();
        final companyName = (res['company_name'] ?? 'Perusahaan').toString();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterEmployeeScreen(
              inviteToken: token.trim(),
              companyId: companyId,
              companyName: companyName,
            ),
          ),
        );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Token Undangan')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      _processToken(barcodes.first.rawValue!);
                    }
                  },
                ),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Atau masukkan token manual:'),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _manualTokenController,
                    label: 'Token',
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    title: 'Validasi Token',
                    onPressed: _loading
                        ? null
                        : () {
                            if (_manualTokenController.text.trim().isNotEmpty) {
                              _processToken(_manualTokenController.text);
                            }
                          },
                    loading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
