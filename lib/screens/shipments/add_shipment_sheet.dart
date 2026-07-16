import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/product_defaults.dart';
import '../../services/api_service.dart';
import '../../models/urun_model.dart';
import '../../models/cihaz_model.dart';
import '../shared/searchable_dropdown.dart';
import '../../core/utils/snackbar_utils.dart';

class _DropdownItem {
  final String label;
  final int cihazId;

  _DropdownItem({required this.label, required this.cihazId});
}

class AddShipmentSheet extends StatefulWidget {
  final VoidCallback onShipmentAdded;

  const AddShipmentSheet({super.key, required this.onShipmentAdded});

  @override
  State<AddShipmentSheet> createState() => _AddShipmentSheetState();
}

class _AddShipmentSheetState extends State<AddShipmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  final _takipNoController = TextEditingController();
  final _kargoFirmasiController = TextEditingController();
  final _ucretController = TextEditingController();
  final _aciklamaController = TextEditingController();

  List<_DropdownItem> _dropdownItems = [];
  _DropdownItem? _selectedItem;

  bool _isLoadingDevices = true;
  bool _isSaving = false;
  String? _error;

  final _arizaIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableDevicesAndProducts();
  }

  @override
  void dispose() {
    _takipNoController.dispose();
    _kargoFirmasiController.dispose();
    _ucretController.dispose();
    _aciklamaController.dispose();
    _arizaIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableDevicesAndProducts() async {
    try {
      // 1. Fetch products, devices, shipments in parallel
      final results = await Future.wait([
        _apiService.urunListele(),
        _apiService.cihazListele(),
        _apiService.sevkiyatListele(),
        _apiService.arizaListele(arizadurumu: 1), // Sadece açık arızalar
      ]);

      final urunler = results[0] as List<dynamic>; // List<UrunModel>
      final cihazlarRaw = results[1] as List<dynamic>; // List<CihazModel>
      final sevkiyatlarRaw = results[2] as List<dynamic>; // List<SevkiyatModel>
      final acikArizalarRaw = results[3] as List<dynamic>; // List<ArizaModel>

      // Açık arızası olan cihazların ID'lerini bul
      final acikArizaCihazIds = acikArizalarRaw
          .map((a) => a.cihazid)
          .whereType<int>()
          .toSet();

      // Tüm sevkiyattaki cihazları bul (Bir ürün sevkiyata sadece bir kez eklenebilir)
      final shipmentCihazIds = sevkiyatlarRaw
          .map((s) => s.cihazid)
          .whereType<int>()
          .toSet();

      final urunMap = {for (var u in urunler) u.id: u};

      // 2. Kısıtlamaları uyguluyoruz (Açık arızası olanlar sevkiyata ÇIKAMAZ)
      final availableCihazlar = cihazlarRaw.where((c) => !acikArizaCihazIds.contains(c.id)).toList();

      final List<_DropdownItem> items = [];

      for (final c in availableCihazlar) {
        final urun = urunMap[c.urunid];

        // Eğer cihazın bağlı olduğu ürün silinmişse (urun null ise), listeye dahil etme
        if (urun == null) continue;

        final categoryPrefix = (urun.kategori != null && urun.kategori!.isNotEmpty) ? '${urun.kategori} - ' : '';

        items.add(
          _DropdownItem(
            label: '$categoryPrefix${urun.ad} - ${c.displayIdentifier}',
            cihazId: c.id,
          ),
        );
      }

      // İsimlerine göre alfabetik sıralayalım
      items.sort((a, b) => a.label.compareTo(b.label));

      if (mounted) {
        setState(() {
          _dropdownItems = items;
          _isLoadingDevices = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Veriler yüklenirken hata oluştu: ${e.message}';
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Beklenmeyen bir hata oluştu: $e';
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _saveShipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final double? ucret = double.tryParse(_ucretController.text.trim());
      final kargoFirma = _kargoFirmasiController.text.trim();
      final takipNo = _takipNoController.text.trim();
      final aciklama = _aciklamaController.text.trim();
      final arizaId = int.tryParse(_arizaIdController.text.trim());

      // Giden Sevkiyat
      if (_selectedItem == null) {
        throw ApiException('Lütfen gönderilecek cihazı/ürünü seçin');
      }
      await _apiService.sevkiyatEkle(
        cihazid: _selectedItem!.cihazId,
        arizaid: arizaId,
        kargofirmasi: kargoFirma,
        takipno: takipNo,
        ucret: ucret,
        yon: 1, // Giden
        aciklama: aciklama.isNotEmpty ? aciklama : null,
      );
      // Cihaz durumunu "Sahada" (3) olarak güncelle
      await _apiService.cihazGuncelle(
        id: _selectedItem!.cihazId,
        cihazdurumu: 3,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onShipmentAdded();
        SnackBarUtils.showTopSnackBar(context, 'Sevkiyat başarıyla oluşturuldu!', isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, e.message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
                        Icons.local_shipping_rounded,
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
                            'Yeni Sevkiyat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            'Gönderilecek cihaz ve kargo bilgilerini girin',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint(context),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          const SizedBox(height: 16),
                          _buildDeviceSelector(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Kargo Firması',
                            controller: _kargoFirmasiController,
                            icon: Icons.business_rounded,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Kargo firması gerekli'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Takip Numarası',
                            controller: _takipNoController,
                            icon: Icons.qr_code_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Kargo Ücreti',
                            controller: _ucretController,
                            icon: Icons.attach_money_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Açıklama / Not (Opsiyonel)',
                            controller: _aciklamaController,
                            icon: Icons.notes_rounded,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving || _isLoadingDevices
                                  ? null
                                  : _saveShipment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor(context),
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
                                      'Sevkiyatı Kaydet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildDeviceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gönderilecek Cihaz / Ürün',
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
                  setState(() => _selectedItem = val);
                },
              ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.accentPink, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _triggerAutocompleteOptions(TextEditingController controller) {
    final text = controller.text;
    controller.value = controller.value.copyWith(
      text: '$text ',
      selection: TextSelection.collapsed(offset: text.length + 1),
    );
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Widget _buildAutocomplete({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Iterable<String> Function(TextEditingValue) optionsBuilder,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: optionsBuilder,
            onSelected: (String selection) {
              if (label == 'Ürün Adı') setState(() {});
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: AppTheme.textHint(context)),
                      prefixIcon: Icon(
                        icon,
                        color: AppTheme.textHint(context),
                        size: 20,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: textEditingController,
                        builder: (context, value, child) {
                          if (value.text.isNotEmpty) {
                            return IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppTheme.textSecondary(context),
                                size: 20,
                              ),
                              onPressed: () {
                                textEditingController.clear();
                                if (label == 'Ürün Adı') setState(() {});
                                focusNode.requestFocus();
                                _triggerAutocompleteOptions(
                                  textEditingController,
                                );
                              },
                            );
                          }
                          return IconButton(
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppTheme.textSecondary(context),
                            ),
                            onPressed: () {
                              if (focusNode.hasFocus) {
                                focusNode.unfocus();
                              } else {
                                focusNode.requestFocus();
                                _triggerAutocompleteOptions(
                                  textEditingController,
                                );
                              }
                            },
                          );
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFillColor(context),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.inputBorderColor(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.inputBorderColor(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor(context),
                        ),
                      ),
                    ),
                    validator: isRequired
                        ? (v) => (v == null || v.trim().isEmpty)
                              ? 'Zorunlu alan'
                              : null
                        : null,
                    onTap: () {
                      if (textEditingController.text.isEmpty) {
                        _triggerAutocompleteOptions(textEditingController);
                      }
                    },
                    onChanged: (v) {
                      if (label == 'Ürün Adı') setState(() {});
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: constraints.maxWidth,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFillColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.inputBorderColor(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppTheme.inputBorderColor(context),
                      ),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
          validator: validator,
        ),
      ],
    );
  }



}
