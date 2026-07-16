import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cihaz_model.dart';
import '../../models/urun_model.dart';
import '../../models/ariza_model.dart';
import '../../services/api_service.dart';
import '../../core/constants/product_defaults.dart';
import '../shared/searchable_dropdown.dart';
import '../../core/utils/snackbar_utils.dart';

class AddAssemblySheet extends StatefulWidget {
  final VoidCallback onSaved;

  const AddAssemblySheet({super.key, required this.onSaved});

  @override
  State<AddAssemblySheet> createState() => _AddAssemblySheetState();
}

class _AddAssemblySheetState extends State<AddAssemblySheet> {
  final _apiService = ApiService.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _savingStatus = '';

  List<UrunModel> _urunler = [];
  List<CihazModel> _tumCihazlar = [];
  List<CihazModel> _tumMusaitBilesenler = [];
  List<CihazModel> _filteredMusaitBilesenler = [];

  // Form State
  bool _isYeniCihazOlusuyor = false;
  final _yeniCihazUrunAdController = TextEditingController();
  final _yeniCihazUrunFocus = FocusNode();
  final _yeniCihazKategoriController = TextEditingController();
  final _yeniCihazKategoriFocus = FocusNode();
  final _yeniCihazSerinoController = TextEditingController();
  final _bilesenSearchController = TextEditingController();

  CihazModel? _selectedAnaCihaz;
  final _aciklamaController = TextEditingController();

  final Set<CihazModel> _selectedBilesenler = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _bilesenSearchController.addListener(_onBilesenSearchChanged);
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _yeniCihazSerinoController.dispose();
    _yeniCihazUrunAdController.dispose();
    _yeniCihazUrunFocus.dispose();
    _yeniCihazKategoriController.dispose();
    _yeniCihazKategoriFocus.dispose();
    _bilesenSearchController.dispose();
    super.dispose();
  }


  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary(context),
      ),
    );
  }

  void _triggerAutocompleteOptions(TextEditingController controller) {
    final currentText = controller.text;
    controller.text = '$currentText ';
    controller.text = currentText;
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
        _label(isRequired ? '$label *' : label),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: optionsBuilder,
            onSelected: (String selection) {
              if (label == 'Ürün Tipi(Türü)') setState(() {});
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onFieldSubmitted: (v) => onFieldSubmitted(),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: hint,
                      prefixIcon: Icon(icon, size: 20),
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
                                if (label == 'Ürün Tipi(Türü)') setState(() {});
                                focusNode.requestFocus();
                                _triggerAutocompleteOptions(textEditingController);
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
                                _triggerAutocompleteOptions(textEditingController);
                              }
                            },
                          );
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFillColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.cardBackground(context),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
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

  void _onBilesenSearchChanged() {

    final query = _bilesenSearchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredMusaitBilesenler = _tumMusaitBilesenler;
      });
      return;
    }

    setState(() {
      _filteredMusaitBilesenler = _tumMusaitBilesenler.where((b) {
        return _getCihazDisplayName(b).toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final urunList = await _apiService.urunListele();
      final cihazListRaw = await _apiService.cihazListele();
      
      // Sadece ürünü hala var olan (silinmemiş) cihazları listeye al
      final urunIds = urunList.map((u) => u.id).toSet();
      final cihazList = cihazListRaw.where((c) => urunIds.contains(c.urunid)).toList();
      
      // Müsait bileşenler: kendi cihaz durumuna göre basit filtreleme
      final musaitler = cihazList.where((c) => c.isMusait).toList();

      if (mounted) {
        setState(() {
          _urunler = urunList;
          _tumCihazlar = cihazList;
          _tumMusaitBilesenler = musaitler;
          _filteredMusaitBilesenler = musaitler;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getCihazDisplayName(CihazModel cihaz) {
    final urun = _urunler.firstWhere(
      (u) => u.id == cihaz.urunid,
      orElse: () =>
          const UrunModel(id: -1, ad: 'Bilinmeyen Ürün', stokadedi: 0),
    );
    
    final categoryPrefix = (urun.kategori != null && urun.kategori!.isNotEmpty) ? '${urun.kategori} - ' : '';
    final sn = ' - ${cihaz.displayIdentifier}';
    return '$categoryPrefix${urun.ad}$sn';
  }

  void _toggleBilesen(CihazModel cihaz) {
    setState(() {
      if (_selectedBilesenler.contains(cihaz)) {
        _selectedBilesenler.remove(cihaz);
      } else {
        _selectedBilesenler.add(cihaz);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isYeniCihazOlusuyor) {
      if (_yeniCihazUrunAdController.text.trim().isEmpty) {
        setState(() => _error = 'Lütfen oluşturulacak yeni cihazın tipini (Ürün) yazınız.');
        return;
      }
      if (_selectedBilesenler.isEmpty) {
        setState(() => _error = 'Lütfen yeni cihaza eklenecek parçaları seçiniz.');
        return;
      }
    } else {
      if (_selectedAnaCihaz == null) {
        setState(() => _error = 'Lütfen tamir edilecek/parça takılacak Ana Cihazı seçiniz.');
        return;
      }
      if (_selectedBilesenler.isEmpty && _aciklamaController.text.trim().isEmpty) {
        setState(() => _error = 'Lütfen takılacak parça seçin veya yapılan işlemi açıklamaya yazın.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _savingStatus = 'Parçalar cihaza bağlanıyor...';
    });

    try {
      int targetAnaCihazId = 0;

      if (_isYeniCihazOlusuyor) {
        final urunAd = _yeniCihazUrunAdController.text.trim();
        final urunKategori = _yeniCihazKategoriController.text.trim();
        int? targetUrunId;

        for (final u in _urunler) {
          if (u.ad.toLowerCase() == urunAd.toLowerCase() &&
              (u.kategori ?? '').toLowerCase() == urunKategori.toLowerCase()) {
            targetUrunId = u.id;
            break;
          }
        }

        if (targetUrunId == null) {
          await _apiService.urunEkle(
            ad: urunAd,
            kategori: urunKategori.isNotEmpty ? urunKategori : null,
          );
          final guncelUrunler = await _apiService.urunListele(arama: urunAd);
          for (final u in guncelUrunler) {
            if (u.ad.toLowerCase() == urunAd.toLowerCase() &&
                (u.kategori ?? '').toLowerCase() == urunKategori.toLowerCase()) {
              targetUrunId = u.id;
              break;
            }
          }
        }

        if (targetUrunId == null) {
          throw Exception('Ürün bulunamadı veya oluşturulamadı.');
        }

        final sn = _yeniCihazSerinoController.text.trim();
        if (sn.isNotEmpty) {
          final allDevices = await _apiService.cihazListele();
          if (allDevices.any((c) => c.serino == sn)) {
            throw Exception('Bu seri no zaten kullanılıyor: $sn');
          }
        }

        await _apiService.cihazEkle(
          urunid: targetUrunId,
          serino: _yeniCihazSerinoController.text.trim().isNotEmpty 
              ? _yeniCihazSerinoController.text.trim() 
              : null,
          miktar: 1,
        );

        final allDevicesAfter = await _apiService.cihazListele(urunid: targetUrunId);
        if (allDevicesAfter.isNotEmpty) {
          final sn = _yeniCihazSerinoController.text.trim();
          if (sn.isNotEmpty) {
            final match = allDevicesAfter.where((c) => c.serino == sn).firstOrNull;
            if (match != null) targetAnaCihazId = match.id;
          } else {
            allDevicesAfter.sort((a, b) => b.id.compareTo(a.id));
            targetAnaCihazId = allDevicesAfter.first.id;
          }
        }

        if (targetAnaCihazId == 0) {
          throw Exception('Yeni cihaz oluşturulamadı veya listede bulunamadı.');
        }

        for (final bilesen in _selectedBilesenler) {
          await _apiService.montajYap(
            anacihazid: targetAnaCihazId,
            bilesencihazid: bilesen.id,
            aciklama: _aciklamaController.text.trim(),
          );
        }

      } else {
        targetAnaCihazId = _selectedAnaCihaz!.id;
        
        if (_selectedBilesenler.isEmpty) {
          await _apiService.stokHareketEkle(
            cihazid: targetAnaCihazId,
            hareket: 1,
            aciklama: 'Tamir/Bakım Notu: ${_aciklamaController.text.trim()}',
          );
        } else {
          for (final bilesen in _selectedBilesenler) {
            await _apiService.montajYap(
              anacihazid: targetAnaCihazId,
              bilesencihazid: bilesen.id,
              aciklama: _aciklamaController.text.trim(),
            );
          }
        }
      }

      bool arizalarKapatilsin = false;
      List<ArizaModel> acikArizalar = [];
      
      if (!_isYeniCihazOlusuyor) {
        try {
          final arizalar = await _apiService.arizaListele(
            cihazid: targetAnaCihazId,
          );
          acikArizalar = arizalar.where((a) => a.isAcik).toList();
        } catch (e) {}
      }

      if (acikArizalar.isNotEmpty && mounted) {
        final result = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Açık Arıza Kaydı Bulundu'),
            content: const Text(
              'Bu cihaza ait açık bir arıza kaydı var. İşlem sonrasında arıza kaydı otomatik olarak kapatılsın mı?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Hayır'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Evet, Kapat'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        arizalarKapatilsin = result == true;
      }

      int hedefDurum = 1;
      if (!_isYeniCihazOlusuyor) {
        try {
          final sevkiyatlar = await _apiService.sevkiyatListele(cihazid: targetAnaCihazId);
          final hasOutgoing = sevkiyatlar.any((s) => s.yon == 1);
          if (hasOutgoing) {
            hedefDurum = 3; // Satıldı
          }
        } catch (_) {}
      }

      if (arizalarKapatilsin) {
        try {
          for (var ariza in acikArizalar) {
            await _apiService.arizaKapat(
              id: ariza.id,
              yenicihazdurumu: hedefDurum,
            );
          }
        } catch (e) {}
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        SnackBarUtils.showTopSnackBar(context, _selectedBilesenler.isEmpty ? 'Bakım/tamir notu eklendi!' : 'Parçalar cihaza başarıyla takıldı!', isError: false);
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
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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
            child: _isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Form(
                    key: _formKey,
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
                                color: const Color(
                                  0xFFF97316,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.developer_board_rounded,
                                color: Color(0xFFF97316),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cihaz Tamiri / Montajı',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                Text(
                                  'Sistemdeki bir cihaza yeni parçalar takın',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppTheme.errorRed),
                            ),
                          ),

                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFillColor(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.inputBorderColor(context)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.precision_manufacturing_rounded,
                                            color: AppTheme.primaryColor(context),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Ürünleri Birleştirerek Yeni Cihaz Oluştur',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Switch.adaptive(
                                        value: _isYeniCihazOlusuyor,
                                        activeColor: AppTheme.primaryColor(context),
                                        onChanged: (val) {
                                          setState(() {
                                            _isYeniCihazOlusuyor = val;
                                            _selectedAnaCihaz = null;
                                            _yeniCihazUrunAdController.clear();
                                            _yeniCihazKategoriController.clear();
                                            _yeniCihazSerinoController.clear();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                if (_isYeniCihazOlusuyor) ...[
                                  _buildAutocomplete(
                                    label: 'Ürün Tipi(Türü)',
                                    hint: 'örn. Güvenlik Kapısı',
                                    icon: Icons.inventory_2_rounded,
                                    controller: _yeniCihazUrunAdController,
                                    focusNode: _yeniCihazUrunFocus,
                                    isRequired: true,
                                    optionsBuilder: (textEditingValue) =>
                                        ProductDefaults.filterCategories(
                                          textEditingValue.text,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAutocomplete(
                                    label: 'Ürün Adı',
                                    hint: 'örn. Turnike Üstü Kiosk',
                                    icon: Icons.label_outline_rounded,
                                    controller: _yeniCihazKategoriController,
                                    focusNode: _yeniCihazKategoriFocus,
                                    isRequired: false,
                                    optionsBuilder: (textEditingValue) {
                                      final mainProduct = _yeniCihazUrunAdController.text.trim();
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
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _yeniCihazSerinoController,
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(color: AppTheme.textPrimary(context)),
                                    decoration: InputDecoration(
                                      labelText: 'Seri No / Varyasyon (Opsiyonel)',
                                      prefixIcon: const Icon(Icons.tag_rounded),
                                      filled: true,
                                      fillColor: AppTheme.inputFillColor(context),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Ana Cihaz Seçimi
                                  SearchableDropdown<CihazModel>(
                                    items: _tumCihazlar,
                                    selectedItem: _selectedAnaCihaz,
                                    hint: 'Tamir Edilecek / Parça Takılacak Cihazı Seçin',
                                    itemLabel: (c) => _getCihazDisplayName(c),
                                    itemSearchString: (c) => _getCihazDisplayName(c),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedAnaCihaz = val;
                                      });
                                    },
                                  ),
                                ],

                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _aciklamaController,
                                  textCapitalization: TextCapitalization.sentences,
                                  keyboardType: TextInputType.text,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Montaj Açıklaması (Opsiyonel)',
                                    prefixIcon: const Icon(
                                      Icons.notes_rounded,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.inputFillColor(
                                      context,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  'İçine Takılacak Parçalar (Çoklu Seçim)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_tumMusaitBilesenler.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputFillColor(context),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Müsait (Boşta) olan hiçbir bileşen/cihaz yok.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary(context),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else ...[
                                  TextField(
                                    controller: _bilesenSearchController,
                                    style: TextStyle(color: AppTheme.textPrimary(context)),
                                    decoration: InputDecoration(
                                      hintText: 'Ürün, seri no veya barkod ile ara...',
                                      hintStyle: TextStyle(color: AppTheme.textHint(context)),
                                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textHint(context)),
                                      filled: true,
                                      fillColor: AppTheme.inputFillColor(context),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: AppTheme.inputFillColor(context),
                                    borderRadius: BorderRadius.circular(16),
                                    clipBehavior: Clip.antiAlias,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 250,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _selectedBilesenler.isEmpty
                                              ? Colors.transparent
                                              : AppTheme.primaryColor(
                                                  context,
                                                ).withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: _filteredMusaitBilesenler.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final b = _filteredMusaitBilesenler[index];
                                          final isSelected = _selectedBilesenler
                                              .contains(b);
                                          return CheckboxListTile(
                                            value: isSelected,
                                            onChanged: (val) =>
                                                _toggleBilesen(b),
                                            title: Text(
                                              _getCihazDisplayName(b),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textPrimary(
                                                  context,
                                                ),
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            activeColor: const Color(
                                              0xFFF97316,
                                            ),
                                            checkColor: Colors.white,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  ), // <-- Closes Material
                                ],
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Kaydet Butonu
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _savingStatus,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Ürünü Oluştur ve Montajla',
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
    );
  }
}
