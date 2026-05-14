// lib/features/auth/presentation/screens/validate_invite_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import 'register_employee_screen.dart';
import '../../../common/widgets/app_dialog.dart';

class ValidateInviteScreen extends StatefulWidget {
  const ValidateInviteScreen({super.key});

  @override
  State<ValidateInviteScreen> createState() => _ValidateInviteScreenState();
}

class _ValidateInviteScreenState extends State<ValidateInviteScreen> {
  final _repo = AuthRepository();
  final _token = TextEditingController();
  bool _loading = false;

  Future<void> _validate() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.validateInvite(_token.text.trim());
      final companyId = (data['company_id'] ?? '').toString();
      final companyName = (data['company_name'] ?? 'Perusahaan').toString();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterEmployeeScreen(
            inviteToken: _token.text.trim(),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validasi Undangan'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Masukkan token undangan dari admin. Pada backend saat ini, scanner barcode belum dibuat di frontend.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _token,
              label: 'Token undangan',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              title: 'Validasi Token',
              onPressed: _validate,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}