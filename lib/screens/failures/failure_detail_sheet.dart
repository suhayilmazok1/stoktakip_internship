import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ariza_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';

class FailureDetailSheet extends StatefulWidget {
  final ArizaModel failure;
  final Function(ArizaModel) onUpdated;
  final Function(int) onDeleted;

  const FailureDetailSheet({
    super.key,
    required this.failure,
    required this.onUpdated,
    required this.onDeleted,
  });

  @override
  State<FailureDetailSheet> createState() => _FailureDetailSheetState();
}

class _FailureDetailSheetState extends State<FailureDetailSheet> {
  final _apiService = ApiService.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _aciklamaController;
  late TextEditingController _neController;
  late TextEditingController _neredeController;
  late TextEditingController _nezamanController;
  late TextEditingController _sorunController;
  late int _arizadurumu;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _aciklamaController = TextEditingController(
      text: widget.failure.aciklama ?? '',
    );
    _neController = TextEditingController(text: widget.failure.ne ?? '');
    _neredeController = TextEditingController(text: widget.failure.nerede ?? '');
    _nezamanController = TextEditingController(text: widget.failure.nezaman ?? '');
    _sorunController = TextEditingController(text: widget.failure.sorun ?? '');
    _arizadurumu = widget.failure.arizadurumu;
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _neController.dispose();
    _neredeController.dispose();
    _nezamanController.dispose();
    _sorunController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor(context),
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor(context),
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _apiService.arizaGuncelle(
        id: widget.failure.id,
        aciklama: _aciklamaController.text.trim(),
        arizadurumu: _arizadurumu,
        ne: _neController.text.trim(),
        nerede: _neredeController.text.trim(),
        nezaman: _nezamanController.text.trim(),
        sorun: _sorunController.text.trim(),
      );

      // Cihaz durumunu arıza durumuna göre senkronize et
      if (_arizadurumu == 1) {
        // Açık arıza -> Cihaz Tamirde (2)
        await _apiService.cihazGuncelle(
          id: widget.failure.cihazid,
          cihazdurumu: 2,
        );
      } else {
        // Kapalı arıza -> Cihaz Müsait (1)
        await _apiService.cihazGuncelle(
          id: widget.failure.cihazid,
          cihazdurumu: 1,
        );
      }

      if (mounted) {
        final updated = ArizaModel(
          id: widget.failure.id,
          cihazid: widget.failure.cihazid,
          serino: widget.failure.serino,
          urunad: widget.failure.urunad,
          alankullaniciid: widget.failure.alankullaniciid,
          teknisyenid: widget.failure.teknisyenid,
          arizadurumu: _arizadurumu,
          aciklama: _aciklamaController.text.trim(),
          tamamlanmatarihi: widget.failure.tamamlanmatarihi,
          ne: _neController.text.trim(),
          nerede: _neredeController.text.trim(),
          nezaman: _nezamanController.text.trim(),
          sorun: _sorunController.text.trim(),
        );

        widget.onUpdated(updated);
        Navigator.pop(context);
        SnackBarUtils.showTopSnackBar(context, 'Arıza güncellendi.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _closeFailure() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      int hedefDurum = 1; // Müsait
      try {
        final sevkiyatlar = await _apiService.sevkiyatListele(cihazid: widget.failure.cihazid);
        final hasOutgoing = sevkiyatlar.any((s) => s.yon == 1);
        if (hasOutgoing) {
          hedefDurum = 3; // Satıldı (önceden sevkiyata gitmişse müsait yapılamaz)
        }
      } catch (_) {}

      await _apiService.arizaKapat(
        id: widget.failure.id,
        yenicihazdurumu: hedefDurum,
      );

      if (mounted) {
        final updated = ArizaModel(
          id: widget.failure.id,
          cihazid: widget.failure.cihazid,
          serino: widget.failure.serino,
          urunad: widget.failure.urunad,
          alankullaniciid: widget.failure.alankullaniciid,
          teknisyenid: widget.failure.teknisyenid,
          arizadurumu: 2, // Kapalı
          aciklama: widget.failure.aciklama,
          tamamlanmatarihi: DateTime.now().toIso8601String(),
        );

        widget.onUpdated(updated);
        Navigator.pop(context);
        SnackBarUtils.showTopSnackBar(context, 'Arıza kapatıldı ve cihaz Müsait durumuna alındı.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteFailure() async {
    if (widget.failure.isAcik) {
          showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardBackground(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
              const SizedBox(width: 8),
              Text('İşlem Engellendi', style: TextStyle(color: AppTheme.textPrimary(ctx))),
            ],
          ),
          content: Text(
            'Açık durumdaki (Tamirde) bir arıza kaydı silinemez. Silmek için önce arızayı kapatın.',
            style: TextStyle(color: AppTheme.textSecondary(ctx)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tamam', style: TextStyle(color: AppTheme.primaryColor(ctx))),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Emin misiniz?'),
        content: const Text(
          'Bu arıza kaydını kalıcı olarak silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondary(ctx)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await _apiService.arizaSil(widget.failure.id);
      if (mounted) {
        widget.onDeleted(widget.failure.id);
        Navigator.pop(context);
        SnackBarUtils.showTopSnackBar(context, 'Arıza kaydı silindi.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textHint(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.failure.isAcik
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        color: widget.failure.isAcik
                            ? AppTheme.accentPink
                            : AppTheme.successGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arıza Detayı',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: #${widget.failure.id}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing) ...[
                      IconButton(
                        onPressed: _isDeleting ? null : _deleteFailure,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppTheme.errorRed,
                        tooltip: 'Sil',
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit_outlined),
                        color: AppTheme.textPrimary(context),
                        tooltip: 'Düzenle',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(),
                        const SizedBox(height: 24),

                        if (_isEditing) ...[
                          _buildTextField(
                            label: 'Arıza Ne?',
                            controller: _neController,
                            icon: Icons.question_mark_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Nerede?',
                            controller: _neredeController,
                            icon: Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ne Zaman?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nezamanController,
                                readOnly: true,
                                onTap: () => _pickDate(_nezamanController),
                                style: TextStyle(color: AppTheme.textPrimary(context)),
                                decoration: InputDecoration(
                                  hintText: 'Tarih seçin',
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      size: 16,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                    onPressed: () => _nezamanController.clear(),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.inputFillColor(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppTheme.inputBorderColor(context),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppTheme.inputBorderColor(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Sorun Ne?',
                            controller: _sorunController,
                            icon: Icons.report_problem_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Açıklama',
                            controller: _aciklamaController,
                            icon: Icons.description_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusDropdown(),
                          const SizedBox(height: 32),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppTheme.accentPink,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                            _aciklamaController.text =
                                                widget.failure.aciklama ?? '';
                                            _neController.text = widget.failure.ne ?? '';
                                            _neredeController.text = widget.failure.nerede ?? '';
                                            _nezamanController.text = widget.failure.nezaman ?? '';
                                            _sorunController.text = widget.failure.sorun ?? '';
                                            _arizadurumu =
                                                widget.failure.arizadurumu;
                                          });
                                        },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                      color: AppTheme.inputBorderColor(context),
                                    ),
                                  ),
                                  child: Text(
                                    'İptal',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentPink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Kaydet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (widget.failure.isAcik)
                            ElevatedButton(
                              onPressed: _isSaving ? null : _closeFailure,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                minimumSize: const Size.fromHeight(56),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.verified_rounded),
                                        SizedBox(width: 8),
                                        Text(
                                          'Onarıldı (Arızayı Kapat)',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.inputBorderColor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            label: 'Cihaz ID',
            value: widget.failure.cihazid.toString(),
            icon: Icons.qr_code_rounded,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            label: 'Durum',
            value: widget.failure.durumAdi,
            icon: Icons.info_outline_rounded,
            valueColor: widget.failure.isAcik
                ? AppTheme.accentPink
                : AppTheme.successGreen,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            label: 'Açıklama',
            value: widget.failure.aciklama?.isNotEmpty == true
                ? widget.failure.aciklama!
                : 'Açıklama yok',
            icon: Icons.description_outlined,
          ),
          if (widget.failure.ne?.isNotEmpty == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              label: 'Arıza Ne?',
              value: widget.failure.ne!,
              icon: Icons.question_mark_rounded,
            ),
          ],
          if (widget.failure.nerede?.isNotEmpty == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              label: 'Nerede?',
              value: widget.failure.nerede!,
              icon: Icons.location_on_rounded,
            ),
          ],
          if (widget.failure.nezaman?.isNotEmpty == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              label: 'Ne Zaman?',
              value: widget.failure.nezaman!,
              icon: Icons.calendar_today_rounded,
            ),
          ],
          if (widget.failure.sorun?.isNotEmpty == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              label: 'Sorun Ne?',
              value: widget.failure.sorun!,
              icon: Icons.report_problem_rounded,
            ),
          ],
          if (widget.failure.tamamlanmatarihi != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              label: 'Kapanış Tarihi',
              value: widget.failure.tamamlanmatarihi!,
              icon: Icons.event_available_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arıza Durumu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.inputBorderColor(context)),
          ),
          child: Material(
            color: Colors.transparent,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _arizadurumu,
                dropdownColor: AppTheme.cardBackground(context),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Açık')),
                  DropdownMenuItem(value: 2, child: Text('Kapalı')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _arizadurumu = val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          maxLines: maxLines,
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppTheme.textHint(context), size: 20)
                : null,
            hintText: label,
            hintStyle: TextStyle(color: AppTheme.textHint(context)),
            filled: true,
            fillColor: AppTheme.inputFillColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.inputBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.inputBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryColor(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textHint(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
