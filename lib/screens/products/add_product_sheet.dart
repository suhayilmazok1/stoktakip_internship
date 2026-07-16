import 'package:flutter/material.dart';
import '../../core/constants/product_defaults.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';

class AddProductSheet extends StatefulWidget {
  final String? defaultKategori;
  final VoidCallback onProductAdded;

  const AddProductSheet({
    super.key,
    this.defaultKategori,
    required this.onProductAdded,
  });

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  // Urun (Katalog) Alanlari
  final _adController = TextEditingController();
  final _markaController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _renkController = TextEditingController();
  final _aciklamaController = TextEditingController();

  final _kategoriFocus = FocusNode();
  final _adFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultKategori != null) {
      _adController.text = widget.defaultKategori!;
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _markaController.dispose();
    _kategoriController.dispose();
    _renkController.dispose();
    _aciklamaController.dispose();
    _kategoriFocus.dispose();
    _adFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ad = _adController.text.trim();
      final kat = _kategoriController.text.trim();

      await _apiService.urunEkle(
        ad: ad,
        marka: _markaController.text.trim(),
        kategori: kat,
        renk: _renkController.text.trim(),
        aciklama: _aciklamaController.text.trim(),
      );

      if (!mounted) return;
      SnackBarUtils.showTopSnackBar(
        context,
        'Yeni ürün başarıyla eklendi!',
        icon: Icons.check_circle_rounded,
      );
      
      Navigator.of(context).pop();
      widget.onProductAdded();
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
                    Icons.add_box_rounded,
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
                        'Yeni Ürün Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Yeni bir ürün tanımı yapın',
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
                      _buildSectionHeader('1. Ürün Bilgileri'),
                      const SizedBox(height: 16),

                      // Ürün Adı (Ana Grup)
                      _buildAutocomplete(
                        label: 'Ürün Tipi(Türü)',
                        hint: 'örn. Güvenlik Kapısı',
                        icon: Icons.inventory_2_rounded,
                        controller: _adController,
                        focusNode: _adFocus,
                        isRequired: true,
                        readOnly: widget.defaultKategori != null,
                        optionsBuilder: (textEditingValue) =>
                            ProductDefaults.filterCategories(
                              textEditingValue.text,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Varyasyon (Alt Ürün)
                      _buildAutocomplete(
                        label: 'Ürün Adı',
                        hint: 'örn. Turnike Üstü Kiosk',
                        icon: Icons.label_outline_rounded,
                        controller: _kategoriController,
                        focusNode: _kategoriFocus,
                        isRequired: false,
                        optionsBuilder: (textEditingValue) {
                          final mainProduct = _adController.text.trim();
                          final defaultProducts =
                              ProductDefaults.productsForCategory(mainProduct);
                          if (defaultProducts.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          if (textEditingValue.text.isEmpty) {
                            return defaultProducts;
                          }
                          return defaultProducts.where(
                            (p) => p.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Marka & Renk
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Marka',
                              _markaController,
                              '',
                              Icons.business_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Renk',
                              _renkController,
                              '',
                              Icons.palette_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Açıklama
                      _label('Açıklama (İsteğe bağlı)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aciklamaController,
                        maxLines: 2,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        decoration: _inputDeco(
                          hint: 'İsteğe bağlı açıklama...',
                          icon: Icons.notes_rounded,
                        ),
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
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(isRequired ? '$label *' : label),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: readOnly ? (_) => const Iterable<String>.empty() : optionsBuilder,
            onSelected: (String selection) {
              if (label == 'Ürün Tipi(Türü)') setState(() {});
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    readOnly: readOnly,
                    style: TextStyle(
                      color: readOnly
                          ? AppTheme.textSecondary(context)
                          : AppTheme.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      filled: readOnly,
                      fillColor: readOnly
                          ? AppTheme.inputBorderColor(context).withValues(alpha: 0.3)
                          : null,
                      hintText: hint,
                      prefixIcon: Icon(icon, size: 20),
                      suffixIcon: readOnly
                          ? null
                          : ValueListenableBuilder<TextEditingValue>(
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
                                      if (label == 'Ürün Tipi(Türü)') {
                                        setState(() {});
                                      }
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    validator: isRequired
                        ? (v) => (v == null || v.trim().isEmpty)
                              ? 'Zorunlu alan'
                              : null
                        : null,
                    onTap: readOnly
                        ? null
                        : () {
                            if (textEditingController.text.isEmpty) {
                              _triggerAutocompleteOptions(textEditingController);
                            }
                          },
                    onChanged: (v) {
                      if (label == 'Ürün Tipi(Türü)') setState(() {});
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  color: AppTheme.cardBackground(context),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppTheme.inputBorderColor(context),
                      ),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            focusNode.unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 14,
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
                      strokeWidth: 2.5,
                      color: AppTheme.textPrimary(context),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Ürünü ve Stoku Kaydet',
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
}
