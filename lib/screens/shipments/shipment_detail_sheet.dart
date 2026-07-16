import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sevkiyat_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';

class ShipmentDetailSheet extends StatefulWidget {
  final SevkiyatModel shipment;
  final ValueChanged<SevkiyatModel>? onUpdated;
  final ValueChanged<int>? onDeleted;

  const ShipmentDetailSheet({
    super.key,
    required this.shipment,
    this.onUpdated,
    this.onDeleted,
  });

  @override
  State<ShipmentDetailSheet> createState() => _ShipmentDetailSheetState();
}

class _ShipmentDetailSheetState extends State<ShipmentDetailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  late TextEditingController _takipNoController;
  late TextEditingController _kargoFirmasiController;
  late TextEditingController _ucretController;
  late int _sevkiyatDurumu;

  @override
  void initState() {
    super.initState();
    _takipNoController = TextEditingController(text: widget.shipment.takipno);
    _kargoFirmasiController = TextEditingController(
      text: widget.shipment.kargofirmasi,
    );
    _ucretController = TextEditingController(
      text: widget.shipment.ucret != null
          ? widget.shipment.ucret.toString()
          : '',
    );
    _sevkiyatDurumu = widget.shipment.sevkiyatdurumu;
  }

  @override
  void dispose() {
    _takipNoController.dispose();
    _kargoFirmasiController.dispose();
    _ucretController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final double? ucret = double.tryParse(_ucretController.text.trim());

      if (widget.shipment.sevkiyatdurumu == 1 && _sevkiyatDurumu == 3) {
        // Arka planda önce "Gönderildi" durumuna alıyoruz
        await _apiService.sevkiyatDurumGuncelle(
          id: widget.shipment.id,
          sevkiyatdurumu: 2,
        );
      }

      await _apiService.sevkiyatGuncelle(
        id: widget.shipment.id,
        takipno: _takipNoController.text.trim(),
        kargofirmasi: _kargoFirmasiController.text.trim(),
        ucret: ucret,
        sevkiyatdurumu: _sevkiyatDurumu,
      );

      final updatedShipment = SevkiyatModel(
        id: widget.shipment.id,
        arizaid: widget.shipment.arizaid,
        cihazid: widget.shipment.cihazid,
        serino: widget.shipment.serino,
        takipno: _takipNoController.text.trim(),
        kargofirmasi: _kargoFirmasiController.text.trim(),
        ucret: ucret,
        sevkiyatdurumu: _sevkiyatDurumu,
        kullaniciid: widget.shipment.kullaniciid,
      );

      if (mounted) {
        widget.onUpdated?.call(updatedShipment);
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        SnackBarUtils.showTopSnackBar(context, 'Sevkiyat başarıyla güncellendi!', isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackBarUtils.showTopSnackBar(context, e.message, isError: true);
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.shipment.sevkiyatdurumu == 1 || widget.shipment.sevkiyatdurumu == 2) {
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
            'Devam eden (Sahada) bir sevkiyat silinemez. Silmek için önce sevkiyatı tamamlayın veya iptal edin.',
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sevkiyatı Sil',
          style: TextStyle(color: AppTheme.textPrimary(context)),
        ),
        content: Text(
          'Bu sevkiyat kaydını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.textHint(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      _deleteShipment();
    }
  }

  Future<void> _deleteShipment() async {
    setState(() => _isDeleting = true);

    try {
      await _apiService.sevkiyatSil(widget.shipment.id);

      // İsteğe bağlı: silinen cihazın durumunu "Sahada"dan "Müsait"e çekebiliriz ama
      // API'de nasıl bir kural varsa ona göre bırakmak daha iyi.

      if (mounted) {
        widget.onDeleted?.call(widget.shipment.id);
        Navigator.pop(context);
        SnackBarUtils.showTopSnackBar(context, 'Sevkiyat silindi.', isError: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        SnackBarUtils.showTopSnackBar(context, e.message, isError: true);
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
              // Handle
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

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: _isEditing
                            ? const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                              )
                            : AppTheme.primaryGradient(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_rounded
                            : Icons.local_shipping_rounded,
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
                            _isEditing
                                ? 'Sevkiyatı Düzenle'
                                : 'Sevkiyat Detayı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing
                                ? 'Kargo ve gönderim bilgilerini güncelleyin'
                                : 'Tüm sevkiyat detaylarını görüntüleyin',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing) ...[
                      IconButton(
                        onPressed: _isDeleting ? null : _confirmDelete,
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
                    ],
                  ],
                ),
              ),

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
                            label: 'Kargo Firması',
                            controller: _kargoFirmasiController,
                            icon: Icons.business_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Takip Numarası',
                            controller: _takipNoController,
                            icon: Icons.qr_code_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Ücret',
                            controller: _ucretController,
                            icon: Icons.attach_money_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusDropdown(),
                          const SizedBox(height: 32),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                            // Geri al
                                            _kargoFirmasiController.text =
                                                widget.shipment.kargofirmasi ??
                                                '';
                                            _takipNoController.text =
                                                widget.shipment.takipno ?? '';
                                            _ucretController.text =
                                                widget.shipment.ucret
                                                    ?.toString() ??
                                                '';
                                            _sevkiyatDurumu =
                                                widget.shipment.sevkiyatdurumu;
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
                                    backgroundColor: AppTheme.primaryColor(
                                      context,
                                    ),
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
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Değişiklikleri Kaydet',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildDetailRow(
                            label: 'Kargo Firması',
                            value:
                                widget.shipment.kargofirmasi?.isNotEmpty == true
                                ? widget.shipment.kargofirmasi!
                                : '-',
                            icon: Icons.business_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Takip Numarası',
                            value: widget.shipment.takipno?.isNotEmpty == true
                                ? widget.shipment.takipno!
                                : '-',
                            icon: Icons.qr_code_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Ücret',
                            value: widget.shipment.ucret != null
                                ? '₺${widget.shipment.ucret!.toStringAsFixed(2)}'
                                : '-',
                            icon: Icons.attach_money_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            label: 'Durum',
                            value: widget.shipment.durumAdi,
                            icon: Icons.info_outline_rounded,
                            valueColor: _getStatusColor(
                              widget.shipment.sevkiyatdurumu,
                            ),
                          ),
                          if (widget.shipment.aciklama != null && widget.shipment.aciklama!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              label: 'Açıklama / Not',
                              value: widget.shipment.aciklama!,
                              icon: Icons.notes_rounded,
                            ),
                          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.device_hub_rounded, color: AppTheme.primaryColor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gönderilen Cihaz',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.shipment.serino?.isNotEmpty == true
                      ? 'SN: ${widget.shipment.serino}'
                      : 'ID: ${widget.shipment.cihazid ?? '-'} (Anonim Cihaz)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
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
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textHint(context), size: 20),
            hintText: label,
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

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sevkiyat Durumu',
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
                value: _sevkiyatDurumu,
                dropdownColor: AppTheme.cardBackground(context),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Hazırlanıyor')),
                  DropdownMenuItem(value: 2, child: Text('Gönderildi')),
                  DropdownMenuItem(value: 3, child: Text('Teslim Edildi')),
                  DropdownMenuItem(value: 4, child: Text('İade')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sevkiyatDurumu = val);
                },
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.inputBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textHint(context)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const Spacer(),
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
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFFFF9800);
      case 2:
        return AppTheme.accentCyan;
      case 3:
        return AppTheme.successGreen;
      case 4:
        return AppTheme.accentPink;
      default:
        return AppTheme.textHint(context);
    }
  }
}
