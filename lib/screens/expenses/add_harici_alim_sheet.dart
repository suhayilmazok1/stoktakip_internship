import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

import '../../models/haricalim_model.dart';
import '../../core/utils/snackbar_utils.dart';

class AddHariciAlimSheet extends StatefulWidget {
  final HariciAlimModel? existingItem;
  final VoidCallback onAdded;

  const AddHariciAlimSheet({
    super.key,
    this.existingItem,
    required this.onAdded,
  });

  @override
  State<AddHariciAlimSheet> createState() => _AddHariciAlimSheetState();
}

class _AddHariciAlimSheetState extends State<AddHariciAlimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  final _urunAdiController = TextEditingController();
  final _tutarController = TextEditingController();
  final _faturaNoController = TextEditingController();
  final _alimTarihiController = TextEditingController();
  final _aciklamaController = TextEditingController();

  bool _isSaving = false;
  bool _isEditing = false;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingItem == null;
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _urunAdiController.text = item.urunadi ?? '';
      _tutarController.text = item.tutar?.toString() ?? '';
      _faturaNoController.text = item.faturano ?? '';
      _alimTarihiController.text = item.alimtarihi ?? '';
      _aciklamaController.text = item.aciklama ?? '';
    }
  }

  @override
  void dispose() {
    _urunAdiController.dispose();
    _tutarController.dispose();
    _faturaNoController.dispose();
    _alimTarihiController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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
      _alimTarihiController.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final tutarText = _tutarController.text.replaceAll(',', '.');
      final tutar = double.tryParse(tutarText);

      if (widget.existingItem == null) {
        await _apiService.haricalimEkle(
          urunadi: _urunAdiController.text,
          tutar: tutar,
          faturano: _faturaNoController.text,
          alimtarihi: _alimTarihiController.text,
          aciklama: _aciklamaController.text,
        );
      } else {
        await _apiService.haricalimGuncelle(
          id: widget.existingItem!.id,
          urunadi: _urunAdiController.text,
          tutar: tutar,
          faturano: _faturaNoController.text,
          alimtarihi: _alimTarihiController.text,
          aciklama: _aciklamaController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        SnackBarUtils.showTopSnackBar(context, widget.existingItem == null
                  ? 'Harici alım başarıyla eklendi!'
                  : 'Harici alım güncellendi!', isError: false);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, _error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.existingItem == null) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await _apiService.haricalimSil(widget.existingItem!.id);
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        SnackBarUtils.showTopSnackBar(context, 'Harici alım başarıyla silindi!', isError: false);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, _error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground(context).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppTheme.inputBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textHint(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
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
                            widget.existingItem == null
                                ? ('Yeni Dışarıdan Alım')
                                : (_isEditing
                                      ? ('Dışarıdan Alım Güncelle')
                                      : ('Dışarıdan Alım Detayı')),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            widget.existingItem == null || _isEditing
                                ? ('Şirket dışı satın alınan ürün faturası')
                                : ('Alım detaylarını görüntüleyin'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.existingItem != null && !_isEditing) ...[
                      IconButton(
                        onPressed: _isDeleting ? null : _delete,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.errorRed,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        color: AppTheme.errorRed,
                        tooltip: 'Sil',
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_outlined),
                        color: AppTheme.textPrimary(context),
                        tooltip: 'Düzenle',
                      ),
                    ] else if (widget.existingItem != null && _isEditing) ...[
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Ürün/Hizmet Adı *',
                            controller: _urunAdiController,
                            icon: Icons.inventory_2_outlined,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Zorunlu alan'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Tutar (₺) *',
                            controller: _tutarController,
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*[\.,]?\d*'),
                              ),
                            ],
                            validator: (val) => val == null || val.isEmpty
                                ? 'Zorunlu alan'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Fatura No',
                            controller: _faturaNoController,
                            icon: Icons.receipt_long_rounded,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                label: 'Alım Tarihi',
                                controller: _alimTarihiController,
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Açıklama',
                            controller: _aciklamaController,
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              if (widget.existingItem != null) ...[
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _delete,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentPink
                                            .withValues(alpha: 0.1),
                                        foregroundColor: AppTheme.accentPink,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Icon(Icons.delete_rounded),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor(
                                        context,
                                      ),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Kaydet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppTheme.textHint(context), size: 20)
                : null,
            filled: true,
            fillColor: AppTheme.inputFillColor(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
