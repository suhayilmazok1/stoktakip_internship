import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/urun_model.dart';
import '../../models/cihaz_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';
import 'add_stock_sheet.dart';

/// Ürün detay ve düzenleme tam ekran sayfa'i.
/// Katalog bilgileri + cihaz detaylarını bir arada gösterir.
class ProductDetailScreen extends StatefulWidget {
  final UrunModel urun;
  final int? initialCihazId;
  final void Function(UrunModel updatedUrun) onUpdated;
  final void Function(int deletedId) onDeleted;

  const ProductDetailScreen({
    super.key,
    required this.urun,
    this.initialCihazId,
    required this.onUpdated,
    required this.onDeleted,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _apiService = ApiService.instance;

  // ── Urun (Katalog) Alanlari ──
  late final TextEditingController _adController;
  late final TextEditingController _kategoriController;
  late final TextEditingController _markaController;
  late final TextEditingController _renkController;
  late final TextEditingController _aciklamaController;

  // ── Cihaz (Stok) Alanlari ──
  List<CihazModel> _cihazlar = [];
  bool _cihazlarLoading = false;
  String? _cihazlarError;
  int? _selectedDurumFilter;

  List<CihazModel> get _displayedCihazlar {
    if (_selectedDurumFilter == null) return _cihazlar;
    return _cihazlar.where((c) => c.cihazdurumu == _selectedDurumFilter).toList();
  }

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final u = widget.urun;
    // UI mapping: ad -> Varyasyon, kategori -> Ürün Adı (Ana kategori)
    _adController = TextEditingController(text: u.ad);
    _kategoriController = TextEditingController(text: u.kategori ?? '');
    _markaController = TextEditingController(text: u.marka ?? '');
    _renkController = TextEditingController(text: u.renk ?? '');
    _aciklamaController = TextEditingController(text: u.aciklama ?? '');

    _loadCihazlar();
  }

  @override
  void dispose() {
    _adController.dispose();
    _kategoriController.dispose();
    _markaController.dispose();
    _renkController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  Future<void> _loadCihazlar() async {
    if (!mounted) return;
    setState(() {
      _cihazlarLoading = true;
      _cihazlarError = null;
    });
    try {
      final list = await _apiService.cihazListele(urunid: widget.urun.id);
      if (!mounted) return;
      setState(() {
        _cihazlar = list;
        _cihazlarLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cihazlarError = e.message;
        _cihazlarLoading = false;
      });
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Ürünü Düzenle' : 'Ürün Detayı',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _isEditing ? 'Alanları düzenleyip kaydedin' : 'Ürün ve stok detayları',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint(context),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              color: AppTheme.textPrimary(context),
              tooltip: 'Düzenle',
            ),
            IconButton(
              onPressed: _isDeleting ? null : _confirmDeleteUrun,
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
          ] else ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: Text(
                'İptal',
                style: TextStyle(color: AppTheme.textSecondary(context)),
              ),
            ),
          ],
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader('1. Ürün Bilgileri'),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          label: 'Ürün Adı',
                          icon: Icons.category_rounded,
                          controller: _adController,
                        ),
                        _buildDetailRow(
                          label: 'Varsa Ürünün Varyasyonu',
                          icon: Icons.label_outline_rounded,
                          controller: _kategoriController,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                label: 'Marka',
                                icon: Icons.business_rounded,
                                controller: _markaController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailRow(
                                label: 'Renk',
                                icon: Icons.palette_outlined,
                                controller: _renkController,
                              ),
                            ),
                          ],
                        ),

                        // Stok Adedi (salt okunur - API'den)
                        if (!_isEditing)
                          _buildInfoChip(
                            label: 'Toplam Müsait Stok',
                            value: '${widget.urun.stokadedi} adet',
                            icon: Icons.inventory_rounded,
                            valueColor: _stokRengi(widget.urun.stokadedi),
                          ),

                        _buildDetailRow(
                          label: 'Açıklama',
                          icon: Icons.notes_rounded,
                          controller: _aciklamaController,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSectionHeader('2. Stok (Cihaz) Bilgileri'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFillColor(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: _selectedDurumFilter,
                                      hint: const Text('Tümü', style: TextStyle(fontSize: 13)),
                                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                                      isDense: true,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedDurumFilter = val;
                                        });
                                      },
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('Tümü')),
                                        DropdownMenuItem(value: 1, child: Text('Müsait')),
                                        DropdownMenuItem(value: 2, child: Text('Tamirde')),
                                        DropdownMenuItem(value: 3, child: Text('Satıldı')),
                                        DropdownMenuItem(value: 4, child: Text('Hurda')),
                                        DropdownMenuItem(value: 5, child: Text('Kayıp')),
                                        DropdownMenuItem(value: 6, child: Text('Montede')),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!_isEditing) ...[
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => AddStockSheet(
                                          urun: widget.urun,
                                          onStockAdded: (addedQty) {
                                            _loadCihazlar(); // Reload locally
                                            // Update parent to reflect the increased stock count
                                            UrunModel updatedUrun = widget.urun.copyWith(stokadedi: widget.urun.stokadedi + addedQty);
                                            widget.onUpdated(updatedUrun);
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Stok Ekle'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor(context),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_cihazlarLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_cihazlarError != null)
                          Text(
                            _cihazlarError!,
                            style: const TextStyle(color: Colors.red),
                          )
                        else if (_cihazlar.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('Bu ürüne ait cihaz/stok bulunamadı.'),
                            ),
                          )
                        else if (_displayedCihazlar.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('Seçilen duruma ait cihaz bulunamadı.'),
                            ),
                          )
                        else
                          ..._displayedCihazlar.map((cihaz) => _buildCihazCard(cihaz)),

                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                        ],
                      ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildCihazCard(CihazModel cihaz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inputBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cihaz.displayIdentifier,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (!_isEditing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<int>(
                      tooltip: 'Durumu Değiştir',
                      icon: Icon(Icons.edit_note_rounded, size: 24, color: AppTheme.textSecondary(context)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (int newStatus) {
                        if (cihaz.cihazdurumu == newStatus) return;
                        _confirmChangeStatus(cihaz, newStatus);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 1, child: Text('Müsait')),
                        PopupMenuItem(value: 2, child: Text('Tamirde')),
                        PopupMenuItem(value: 3, child: Text('Satıldı')),
                        PopupMenuItem(value: 4, child: Text('Hurda')),
                        PopupMenuItem(value: 5, child: Text('Kayıp')),
                        PopupMenuItem(value: 6, child: Text('Montede')),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _confirmDeleteCihaz(cihaz),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorRed),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Bu cihazı sil',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Durum Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cihaz.isMusait 
                  ? AppTheme.successGreen.withValues(alpha: 0.1) 
                  : AppTheme.primaryColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cihaz.isMusait ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: cihaz.isMusait ? AppTheme.successGreen : AppTheme.primaryColor(context),
                ),
                const SizedBox(width: 4),
                Text(
                  cihaz.durumAdi,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cihaz.isMusait ? AppTheme.successGreen : AppTheme.primaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (cihaz.lokasyon != null && cihaz.lokasyon!.isNotEmpty)
            _buildCihazInfoRow(Icons.location_on_outlined, 'Lokasyon', cihaz.lokasyon!),
          if (cihaz.alimtarihi != null && cihaz.alimtarihi!.isNotEmpty)
            _buildCihazInfoRow(Icons.calendar_today_rounded, 'Alım Tarihi', cihaz.alimtarihi!),
          if (cihaz.ureticigarantibitis != null && cihaz.ureticigarantibitis!.isNotEmpty)
            _buildCihazInfoRow(Icons.shield_outlined, 'Üretici Garanti Bitiş', cihaz.ureticigarantibitis!),
          if (cihaz.bizimgarantibitis != null && cihaz.bizimgarantibitis!.isNotEmpty)
            _buildCihazInfoRow(Icons.verified_user_outlined, 'Bizim Garanti Bitiş', cihaz.bizimgarantibitis!),
          if (cihaz.ureticibarkod != null && cihaz.ureticibarkod!.isNotEmpty)
            _buildCihazInfoRow(Icons.qr_code_2_rounded, 'Üretici Barkodu', cihaz.ureticibarkod!),
          if (cihaz.bizimbarkod != null && cihaz.bizimbarkod!.isNotEmpty)
            _buildCihazInfoRow(Icons.qr_code_scanner_rounded, 'Bizim Barkodumuz', cihaz.bizimbarkod!),
        ],
      ),
    );
  }

  Widget _buildCihazInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textHint(context)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Detay Satırı ──────────────────────────────────────────────────
  Widget _buildDetailRow({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final hasValue = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: InputDecoration(
                hintText: '$label girin...',
                prefixIcon: Icon(icon, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.textHint(context),
                        ),
                        onPressed: () {
                          controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.inputFillColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.inputBorderColor(context)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.textSecondary(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasValue ? controller.text : '-',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasValue
                            ? AppTheme.textPrimary(context)
                            : AppTheme.textHint(context),
                      ),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Bilgi Chip'i ──────────────────────────────────────────────────
  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inputFillColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.inputBorderColor(context)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: valueColor ?? AppTheme.textSecondary(context),
                ),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Kaydet Butonu ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: _isSaving
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
              ),
        color: _isSaving ? AppTheme.inputFillColor(context) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isSaving
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _save,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.textPrimary(context),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Değişiklikleri Kaydet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Kaydet ────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      // 1. Ürün Güncelle
      await _apiService.urunGuncelle(
        id: widget.urun.id,
        ad: _adController.text.trim(),
        kategori: _kategoriController.text.trim(),
        marka: _markaController.text.trim(),
        renk: _renkController.text.trim(),
        aciklama: _aciklamaController.text.trim(),
      );

      if (!mounted) return;
      // Lokal model oluştur – API tekrar çağrılmaz
      final updatedUrun = UrunModel(
        id: widget.urun.id,
        ad: _adController.text.trim(),
        kategori: _kategoriController.text.trim(),
        marka: _markaController.text.trim(),
        renk: _renkController.text.trim(),
        aciklama: _aciklamaController.text.trim(),
        stokadedi: widget.urun.stokadedi,
      );
      
      setState(() => _isEditing = false);
      widget.onUpdated(updatedUrun);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Ürün ve stok başarıyla güncellendi!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: AppTheme.accentPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 16,
              right: 16,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Ürün Silme Onayı (Tümü) ──────────────────────────────────────────
  Future<void> _confirmDeleteUrun() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.accentPink,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Ürünü Sil',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '"${widget.urun.ad}" ürününü ve altındaki tüm cihaz/stok kayıtlarını tamamen silmek istediğinizden emin misiniz?',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Vazgeç',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteUrun();
    }
  }

  Future<void> _deleteUrun() async {
    if (!mounted) return;
    setState(() => _isDeleting = true);

    try {
      await _apiService.urunSil(id: widget.urun.id);

      if (!mounted) return;
      
      SnackBarUtils.showTopSnackBar(
        context,
        'Ürün ve cihazları başarıyla silindi.',
        icon: Icons.delete_rounded,
      );
      
      // Notify parent to remove the product from the list
      widget.onDeleted(widget.urun.id);
      
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: AppTheme.accentPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 16,
              right: 16,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ─── Tek Cihaz Silme Onayı ──────────────────────────────────────────
  void _confirmChangeStatus(CihazModel cihaz, int newStatus) {
    final statusNames = {
      1: 'Müsait',
      2: 'Tamirde',
      3: 'Satıldı',
      4: 'Hurda',
      5: 'Kayıp',
      6: 'Montede',
    };
    final newStatusName = statusNames[newStatus] ?? 'Bilinmeyen Durum';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durumu Değiştir'),
        content: Text('Bu cihazın durumunu "$newStatusName" olarak değiştirmek istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _changeCihazStatus(cihaz, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Değiştir'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeCihazStatus(CihazModel cihaz, int newStatus) async {
    try {
      await _apiService.cihazGuncelle(id: cihaz.id, cihazdurumu: newStatus);
      if (mounted) {
        SnackBarUtils.showTopSnackBar(
          context,
          'Durum başarıyla güncellendi.',
          icon: Icons.check_circle_rounded,
        );
        _loadCihazlar(); // reload to reflect changes
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showTopSnackBar(
          context,
          'Hata: $e',
          icon: Icons.error_outline_rounded,
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmDeleteCihaz(CihazModel cihaz) async {
    final categoryPrefix = (widget.urun.kategori != null && widget.urun.kategori!.isNotEmpty) ? '${widget.urun.kategori} - ' : '';
    final sn = ' - ${cihaz.displayIdentifier}';
    final cihazBaslik = '$categoryPrefix${widget.urun.ad}$sn';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.accentPink,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cihazı Sil',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '"$cihazBaslik" cihazını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Vazgeç',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cihazı Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteCihaz(cihaz);
    }
  }

  Future<void> _deleteCihaz(CihazModel cihaz) async {
    if (!mounted) return;
    setState(() => _isDeleting = true);

    try {
      await _apiService.cihazSil(id: cihaz.id);

      if (!mounted) return;
      
      SnackBarUtils.showTopSnackBar(
        context,
        'Cihaz başarıyla silindi.',
        icon: Icons.delete_rounded,
      );
      
      // Update local UrunModel stock to reflect deletion
      UrunModel updatedUrun = widget.urun;
      if (widget.urun.stokadedi > 0) {
        updatedUrun = widget.urun.copyWith(stokadedi: widget.urun.stokadedi - 1);
      }
      
      // Notify parent so it updates the UI immediately
      widget.onUpdated(updatedUrun);
      
      _loadCihazlar();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showTopSnackBar(
        context,
        e.message,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Color _stokRengi(int stok) {
    if (stok > 10) return AppTheme.successGreen;
    if (stok > 0) return const Color(0xFFFF9800);
    return AppTheme.accentPink;
  }
}
