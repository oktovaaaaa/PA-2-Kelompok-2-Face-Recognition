import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.getCompanySettings();
      _name.text = res['name'] ?? '';
      _email.text = res['email'] ?? '';
      _phone.text = res['phone'] ?? '';
      _address.text = res['address'] ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repo.updateCompanySettings({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan Perusahaan berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 20),
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'Pengaturan Perusahaan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                AppTextField(controller: _name, label: 'Nama Perusahaan', validator: _required, prefixIcon: Icons.business_rounded),
                                const SizedBox(height: 16),
                                AppTextField(controller: _email, label: 'Email Perusahaan', keyboardType: TextInputType.emailAddress, validator: _required, prefixIcon: Icons.email_rounded),
                                const SizedBox(height: 16),
                                AppTextField(controller: _phone, label: 'Telepon Perusahaan', keyboardType: TextInputType.phone, validator: _required, prefixIcon: Icons.phone_rounded),
                                const SizedBox(height: 16),
                                AppTextField(controller: _address, label: 'Alamat Perusahaan', validator: _required, prefixIcon: Icons.location_on_rounded, maxLines: 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          PrimaryButton(title: 'Simpan Perubahan', onPressed: _save, loading: _saving),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
