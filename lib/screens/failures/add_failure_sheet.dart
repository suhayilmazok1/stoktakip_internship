import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../shared/searchable_dropdown.dart';
import '../../core/utils/snackbar_utils.dart';

class AddFailureSheet extends StatefulWidget {
  final VoidCallback onFailureAdded;

  const AddFailureSheet({super.key, required this.onFailureAdded});

  @override
  State<AddFailureSheet> createState() => _AddFailureSheetState();
}

class _DropdownItem {
  final String label;
  final int cihazId;

  _DropdownItem({required this.label, required this.cihazId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DropdownItem &&
          runtimeType == other.runtimeType &&
          cihazId == other.cihazId;

  @override
  int get hashCode => cihazId.hashCode;
}

class _AddFailureSheetState extends State<AddFailureSheet> {
  final _apiService = ApiService.instance;
  final _formKey = GlobalKey<FormState>();

  final _aciklamaController = TextEditingController();
  final _neController = TextEditingController();
  final _neredeController = TextEditingController();
  final _nezamanController = TextEditingController();
  final _sorunController = TextEditingController();

  List<_DropdownItem> _dropdownItems = [];
  _DropdownItem? _selectedItem;

  bool _isLoadingDevices = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableDevicesAndProducts();
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

  Future<void> _loadAvailableDevicesAndProducts() async {
    try {
      final results = await Future.wait([
        _apiService.urunListele(),
        _apiService.cihazListele(),
        _apiService.sevkiyatListele(),
      ]);

      final urunler = results[0] as List<dynamic>;
      final cihazlarRaw = results[1] as List<dynamic>;
      final sevkiyatlarRaw = results[2] as List<dynamic>;

      final urunMap = {for (var u in urunler) u.id: u};

      // Herhangi bir durumdaki cihaza arıza kaydı açılabilmesi için kısıtlamaları kaldırıyoruz
      final availableCihazlar = cihazlarRaw.toList();

      final Map<int, List<dynamic>> anonymousByUrun = {};
      final List<_DropdownItem> items = [];

      for (final c in availableCihazlar) {
        final urun = urunMap[c.urunid];

        // Eğer cihazın bağlı olduğu ürün silinmişse (urun null ise), listeye dahil etme
        if (urun == null) continue;

        final categoryPrefix = (urun.kategori != null && urun.kategori!.isNotEmpty) ? '${urun.kategori} - ' : '';

        if (c.serino != null && c.serino!.trim().isNotEmpty) {
          items.add(
            _DropdownItem(label: '$categoryPrefix${urun.ad} - ${c.displayIdentifier}', cihazId: c.id),
          );
        } else {
          anonymousByUrun.putIfAbsent(c.urunid, () => []).add(c);
        }
      }

      for (final entry in anonymousByUrun.entries) {
        final urunId = entry.key;
        final cihazList = entry.value;
        final urun = urunMap[urunId];
        final categoryPrefix = (urun != null && urun.kategori != null && urun.kategori!.isNotEmpty) ? '${urun.kategori} - ' : '';

        items.add(
          _DropdownItem(
            label: '$categoryPrefix${urun?.ad ?? 'Bilinmeyen Ürün'} (${cihazList.length} adet müsait)',
            cihazId: cihazList.first.id,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _dropdownItems = items;
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Cihazlar yüklenemedi: $e';
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _saveFailure() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null) {
      setState(() => _error = 'Lütfen arızalanan cihazı seçin.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final response = await _apiService.arizaAc(
        cihazid: _selectedItem!.cihazId,
        ne: _neController.text.trim(),
        nerede: _neredeController.text.trim(),
        nezaman: _nezamanController.text.trim(),
        sorun: _sorunController.text.trim(),
        aciklama: _aciklamaController.text.trim(),
      );

      // Cihaz durumunu "Tamirde" (2) olarak güncelle
      await _apiService.cihazGuncelle(
        id: _selectedItem!.cihazId,
        cihazdurumu: 2,
      );

      String? yeniArizaId;
      final data = response['data'];
      if (data is List && data.isNotEmpty) {
        yeniArizaId = data[0]['id']?.toString();
      } else if (data is Map && data['id'] != null) {
        yeniArizaId = data['id'].toString();
      }

      if (mounted) {
        widget.onFailureAdded();
        Navigator.pop(context);
        SnackBarUtils.showTopSnackBar(context, yeniArizaId != null 
                  ? 'Arıza kaydı başarıyla oluşturuldu. (Arıza ID: $yeniArizaId)' 
                  : 'Arıza kaydı başarıyla oluşturuldu.', isError: false);
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

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textHint(
                          context,
                        ).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          color: AppTheme.accentPink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Arıza Bildirimi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Arızalanan cihazı seçin ve açıklama girin',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Cihaz Seçimi
                  Text(
                    'Arızalanan Cihaz / Ürün',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingDevices
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SearchableDropdown<_DropdownItem>(
                          items: _dropdownItems,
                          selectedItem: _selectedItem,
                          hint: 'Cihaz Seçin',
                          itemLabel: (item) => item.label,
                          itemSearchString: (item) => item.label,
                          onChanged: (val) {
                            setState(() {
                              _selectedItem = val;
                            });
                          },
                        ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

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

                  // Açıklama
                  _buildTextField(
                    label: 'Arıza Açıklaması / Detay',
                    controller: _aciklamaController,
                    icon: Icons.description_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

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

                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveFailure,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Arızayı Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
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
}
