import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/urun_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../shared/searchable_dropdown.dart';

class AddStockSheet extends StatefulWidget {
  final UrunModel urun;
  final void Function(int addedQty) onStockAdded;

  const AddStockSheet({
    super.key,
    required this.urun,
    required this.onStockAdded,
  });

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;



  // Cihaz (Stok) Alanlari
  bool _isSeriNumarali = false;
  final _serinoController = TextEditingController();
  final _miktarController = TextEditingController(text: '1');
  final _lokasyonController = TextEditingController();
  final _alimTarihiController = TextEditingController();
  final _ureticiGarantiController = TextEditingController();
  final _bizimGarantiController = TextEditingController();
  final _ureticiBarkodController = TextEditingController();
  final _bizimBarkodController = TextEditingController();

  bool _isSubmitting = false;



  @override
  void dispose() {
    _serinoController.dispose();
    _miktarController.dispose();
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
      String? sn;
      int miktar = 1;

      if (_isSeriNumarali) {
        sn = _serinoController.text.trim();
        miktar = 1;

        if (sn.isNotEmpty) {
          final currentDevices = await _apiService.cihazListele();
          final isDuplicate = currentDevices.any((c) => c.serino == sn);
          if (isDuplicate) {
            throw ApiException('Bu seri no zaten kullanılıyor!');
          }
        }
      } else {
        sn = null;
        miktar = int.tryParse(_miktarController.text.trim()) ?? 1;
      }

      int basariliEkleme = 0;
      String? lastError;

      for (int i = 0; i < miktar; i++) {
        try {
          String? currentBizimBarkod = _bizimBarkodController.text.trim();
          String? currentUreticiBarkod = _ureticiBarkodController.text.trim();
          
          if (i > 0) {
            if (currentBizimBarkod.isNotEmpty) currentBizimBarkod = '$currentBizimBarkod-$i';
            if (currentUreticiBarkod.isNotEmpty) currentUreticiBarkod = '$currentUreticiBarkod-$i';
          }

          await _apiService.cihazEkle(
            urunid: widget.urun.id,
            serino: sn?.isNotEmpty == true ? sn : null,
            miktar: 1, // Her bir cihaz için ayrı kayıt oluşturur
            lokasyon: _lokasyonController.text.trim(),
            alimtarihi: _alimTarihiController.text.trim(),
            ureticigarantibitis: _ureticiGarantiController.text.trim(),
            bizimgarantibitis: _bizimGarantiController.text.trim(),
            ureticibarkod: currentUreticiBarkod,
            bizimbarkod: currentBizimBarkod,
          );
          basariliEkleme++;
          
          // Sunucunun üst üste gelen hızlı istekleri engellememesi için bekleme süresi
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          lastError = e is ApiException ? e.message : 'Bilinmeyen bir hata oluştu ($e)';
          break; // İlk hatada döngüyü durdur
        }
      }

      if (!mounted) return;
      
      if (basariliEkleme > 0) {
        SnackBarUtils.showTopSnackBar(
          context,
          lastError != null 
              ? '$basariliEkleme adet eklendi fakat sonrakilerde hata çıktı: $lastError'
              : '$basariliEkleme adet stok başarıyla eklendi!',
          icon: lastError != null ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          isError: lastError != null,
        );
        Navigator.of(context).pop();
        widget.onStockAdded(basariliEkleme);
      } else {
        SnackBarUtils.showTopSnackBar(
          context,
          lastError ?? 'Stok eklenemedi',
          isError: true,
        );
      }
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
                    Icons.inventory_rounded,
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
                        'Stok Girişi Yap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ürün seçin ve stoğa ekleyin',
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
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.inputBorderColor(context), height: 1),

          // Form
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
                      // Ürün Bilgisi Özeti
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor(context).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor(context).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: AppTheme.primaryColor(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.urun.ad,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  if (widget.urun.kategori != null && widget.urun.kategori!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.urun.kategori!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader('Stok Bilgileri'),
                                const SizedBox(height: 16),

                                // Seri Numarası Var mı? Switch
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFillColor(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.inputBorderColor(context),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.qr_code_scanner_rounded,
                                            color: AppTheme.primaryColor(context),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Ürün Seri Numaralı mı?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Switch.adaptive(
                                        value: _isSeriNumarali,
                                        activeTrackColor: AppTheme.primaryColor(
                                          context,
                                        ).withValues(alpha: 0.5),
                                        activeThumbColor: AppTheme.primaryColor(context),
                                        onChanged: (v) {
                                          setState(() {
                                            _isSeriNumarali = v;
                                            if (!v) {
                                              _serinoController.clear();
                                            } else {
                                              _miktarController.text = '1';
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                if (_isSeriNumarali) ...[
                                  // Seri No
                                  _field(
                                    'Seri Numarası',
                                    _serinoController,
                                    'Seri numarasını giriniz',
                                    Icons.tag_rounded,
                                    isRequired: true,
                                  ),
                                ] else ...[
                                  // Miktar
                                  _field(
                                    'Miktar (Adet)',
                                    _miktarController,
                                    'örn. 10',
                                    Icons.numbers_rounded,
                                    keyboardType: TextInputType.number,
                                    isRequired: true,
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // Lokasyon
                                _field(
                                  'Lokasyon',
                                  _lokasyonController,
                                  '',
                                  Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 16),

                                // Tarihler
                                Row(
                                  children: [
                                    Expanded(
                                      child: _dateField(
                                        'Alım Tarihi',
                                        _alimTarihiController,
                                        'Tarih seçin',
                                        Icons.calendar_today_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _dateField(
                                        'Üretici G. Bitiş',
                                        _ureticiGarantiController,
                                        'Tarih seçin',
                                        Icons.shield_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                _dateField(
                                  'Bizim Garanti Bitiş',
                                  _bizimGarantiController,
                                  'Tarih seçin',
                                  Icons.verified_user_outlined,
                                ),
                                const SizedBox(height: 16),
                                _field(
                                  'Üreticinin Barkod Numarası',
                                  _ureticiBarkodController,
                                  '',
                                  Icons.qr_code_2_rounded,
                                ),
                                const SizedBox(height: 16),
                                _field(
                                  'Bizim Barkod Numaramız',
                                  _bizimBarkodController,
                                  '',
                                  Icons.qr_code_scanner_rounded,
                                ),

                                const SizedBox(height: 32),

                                // Kaydet
                                _buildSubmitButton(),
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

  // ── Yardımcılar ──

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryColor(context),
        letterSpacing: 0.3,
      ),
    );
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: _isSubmitting ? null : AppTheme.primaryGradient(context),
        color: _isSubmitting ? AppTheme.inputFillColor(context) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isSubmitting
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.inputFillColor(context),
                    ),
                  )
                : const Text(
                    'Stoğa Ekle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
