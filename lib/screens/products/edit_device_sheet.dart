import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cihaz_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';

class EditDeviceSheet extends StatefulWidget {
  final CihazModel cihaz;
  final VoidCallback onDeviceUpdated;

  const EditDeviceSheet({
    super.key,
    required this.cihaz,
    required this.onDeviceUpdated,
  });

  @override
  State<EditDeviceSheet> createState() => _EditDeviceSheetState();
}

class _EditDeviceSheetState extends State<EditDeviceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  late TextEditingController _serinoController;
  late TextEditingController _lokasyonController;
  late TextEditingController _alimTarihiController;
  late TextEditingController _ureticiGarantiController;
  late TextEditingController _bizimGarantiController;
  late TextEditingController _ureticiBarkodController;
  late TextEditingController _bizimBarkodController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _serinoController = TextEditingController(text: widget.cihaz.serino);
    _lokasyonController = TextEditingController(text: widget.cihaz.lokasyon);
    _alimTarihiController = TextEditingController(text: widget.cihaz.alimtarihi);
    _ureticiGarantiController = TextEditingController(text: widget.cihaz.ureticigarantibitis);
    _bizimGarantiController = TextEditingController(text: widget.cihaz.bizimgarantibitis);
    _ureticiBarkodController = TextEditingController(text: widget.cihaz.ureticibarkod);
    _bizimBarkodController = TextEditingController(text: widget.cihaz.bizimbarkod);
  }

  @override
  void dispose() {
    _serinoController.dispose();
    _lokasyonController.dispose();
    _alimTarihiController.dispose();
    _ureticiGarantiController.dispose();
    _bizimGarantiController.dispose();
    _ureticiBarkodController.dispose();
    _bizimBarkodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _apiService.cihazGuncelle(
        id: widget.cihaz.id,
        serino: _serinoController.text.trim().isNotEmpty ? _serinoController.text.trim() : null,
        lokasyon: _lokasyonController.text.trim(),
        alimtarihi: _alimTarihiController.text.trim(),
        ureticigarantibitis: _ureticiGarantiController.text.trim(),
        bizimgarantibitis: _bizimGarantiController.text.trim(),
        ureticibarkod: _ureticiBarkodController.text.trim(),
        bizimbarkod: _bizimBarkodController.text.trim(),
      );

      if (!mounted) return;
      SnackBarUtils.showTopSnackBar(
        context,
        'Cihaz bilgileri başarıyla güncellendi!',
        icon: Icons.check_circle_rounded,
      );
      
      Navigator.of(context).pop();
      widget.onDeviceUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showTopSnackBar(
        context,
        e.message,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor(context),
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppTheme.textSecondary(context),
    ),
  );

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(isRequired ? '$label *' : label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppTheme.textPrimary(context)),
          decoration: _inputDeco(hint: hint, icon: icon),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null
              : null,
        ),
      ],
    );
  }

  Widget _dateField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _pickDate(controller),
          style: TextStyle(color: AppTheme.textPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear_rounded,
                size: 16,
                color: AppTheme.textSecondary(context),
              ),
              onPressed: () => controller.clear(),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cihazı Düzenle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${widget.cihaz.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.inputBorderColor(context), height: 1),

          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field('Seri Numarası', _serinoController, 'Varsa seri numarası', Icons.tag_rounded),
                      const SizedBox(height: 16),
                      _field('Lokasyon', _lokasyonController, '', Icons.location_on_outlined),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _dateField('Alım Tarihi', _alimTarihiController, 'Tarih', Icons.calendar_today_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dateField('Üretici G. Bitiş', _ureticiGarantiController, 'Tarih', Icons.shield_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _dateField('Bizim Garanti Bitiş', _bizimGarantiController, 'Tarih seçin', Icons.verified_user_outlined),
                      const SizedBox(height: 16),
                      _field('Üreticinin Barkod Numarası', _ureticiBarkodController, '', Icons.qr_code_2_rounded),
                      const SizedBox(height: 16),
                      _field('Bizim Barkod Numaramız', _bizimBarkodController, '', Icons.qr_code_scanner_rounded),
                      const SizedBox(height: 32),
                      
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: _isSubmitting ? null : AppTheme.primaryGradient(context),
                          color: _isSubmitting ? AppTheme.inputFillColor(context) : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _submit,
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: _isSubmitting
                                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.inputFillColor(context)))
                                  : const Text('Güncelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
