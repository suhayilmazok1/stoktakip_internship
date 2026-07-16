import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sevkiyat_model.dart';
import '../../models/cihaz_model.dart';
import '../../models/urun_model.dart';
import '../../services/api_service.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';
import '../../core/utils/date_utils.dart';
import 'add_shipment_sheet.dart';
import 'shipment_detail_sheet.dart';
import '../../core/utils/snackbar_utils.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  final _apiService = ApiService.instance;

  List<SevkiyatModel> _allShipments = [];
  Map<int, CihazModel> _cihazMap = {};
  Map<int, UrunModel> _urunMap = {};
  bool _isLoading = true;
  String? _error;

  int _selectedFilter =
      0; // 0: Tümü, 1: Hazırlanıyor, 2: Gönderildi, 3: Teslim Edildi, 4: İade

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShipments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.sevkiyatListele(),
        _apiService.cihazListele(),
        _apiService.urunListele(),
      ]);

      final sevkiyatList = results[0] as List<dynamic>;
      final cihazList = results[1] as List<dynamic>;
      final urunList = results[2] as List<dynamic>;

      if (mounted) {
        setState(() {
          _cihazMap = {for (var c in cihazList) c.id: c as CihazModel};
          _urunMap = {for (var u in urunList) u.id: u as UrunModel};

          final list = List<SevkiyatModel>.from(sevkiyatList);
          _allShipments = list..sort((a, b) => b.id.compareTo(a.id));
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(SevkiyatModel shipment, int newStatus) async {
    try {
      if (shipment.sevkiyatdurumu == 1 && newStatus == 3) {
        // Arka planda önce "Gönderildi" durumuna alıyoruz
        await _apiService.sevkiyatDurumGuncelle(
          id: shipment.id,
          sevkiyatdurumu: 2,
        );
      }

      await _apiService.sevkiyatDurumGuncelle(
        id: shipment.id,
        sevkiyatdurumu: newStatus,
      );

      // Update local state
      if (mounted) {
        setState(() {
          final idx = _allShipments.indexWhere((s) => s.id == shipment.id);
          if (idx != -1) {
            _allShipments[idx] = SevkiyatModel(
              id: shipment.id,
              arizaid: shipment.arizaid,
              cihazid: shipment.cihazid,
              serino: shipment.serino,
              takipno: shipment.takipno,
              kargofirmasi: shipment.kargofirmasi,
              ucret: shipment.ucret,
              sevkiyatdurumu: newStatus,
              kullaniciid: shipment.kullaniciid,
            );
          }
        });
        SnackBarUtils.showTopSnackBar(context, 'Sevkiyat durumu güncellendi.', isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, e.message, isError: true);
      }
    }
  }

  List<SevkiyatModel> get _displayedShipments {
    List<SevkiyatModel> filtered = _allShipments;
    
    if (_selectedFilter != 0) {
      filtered = filtered.where((s) => s.sevkiyatdurumu == _selectedFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final cihaz = _cihazMap[s.cihazid];
        final urun = cihaz != null ? _urunMap[cihaz.urunid] : null;

        return (s.serino != null && s.serino!.toLowerCase().contains(_searchQuery)) ||
               (s.takipno != null && s.takipno!.toLowerCase().contains(_searchQuery)) ||
               (cihaz?.serino != null && cihaz!.serino!.toLowerCase().contains(_searchQuery)) ||
               (cihaz?.ureticibarkod != null && cihaz!.ureticibarkod!.toLowerCase().contains(_searchQuery)) ||
               (cihaz?.bizimbarkod != null && cihaz!.bizimbarkod!.toLowerCase().contains(_searchQuery)) ||
               (urun != null && urun.ad.toLowerCase().contains(_searchQuery));
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShipmentSheet(context),
        backgroundColor: AppTheme.primaryColor(context),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sevkiyatlar',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Ürün, seri no veya barkod ile ara...',
          hintStyle: TextStyle(color: AppTheme.textHint(context)),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textHint(context)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.textHint(context)),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.inputFillColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 0, 'label': 'Tümü'},
      {'id': 1, 'label': 'Hazırlanıyor'},
      {'id': 2, 'label': 'Gönderildi'},
      {'id': 3, 'label': 'Teslim Edildi'},
      {'id': 4, 'label': 'İade'},
    ];

    return Column(
      children: [

        // Durum Filtreleri
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: filters.map((f) {
              final id = f['id'] as int;
              final label = f['label'] as String;
              final isSelected = _selectedFilter == id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = id);
                  },
                  selectedColor: AppTheme.primaryColor(
                    context,
                  ).withValues(alpha: 0.2),
                  backgroundColor: AppTheme.inputFillColor(context),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor(context)
                        : AppTheme.textSecondary(context),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor(context)
                        : AppTheme.inputBorderColor(context),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoadingList();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final list = _displayedShipments;

    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.local_shipping_rounded,
        title: 'Sevkiyat Bulunamadı',
        subtitle: 'Seçili filtrelere uygun sevkiyat kaydı bulunmuyor.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildShipmentCard(list[index]),
    );
  }

  Widget _buildShipmentCard(SevkiyatModel shipment) {
    final statusColor = _getStatusColor(shipment.sevkiyatdurumu);

    String cihazAd = 'ID:${shipment.cihazid ?? '-'} (Anonim)';
    if (shipment.cihazid != null) {
      final cihaz = _cihazMap[shipment.cihazid!];
      if (cihaz != null) {
        final urun = _urunMap[cihaz.urunid];
        if (urun != null) {
          cihazAd = urun.ad;
          if (urun.kategori != null && urun.kategori!.isNotEmpty) {
            cihazAd += ' - ${urun.kategori}';
          }
          cihazAd += ' (SN: ${cihaz.displaySeriNo})';
        } else {
          cihazAd = 'SN: ${cihaz.displaySeriNo}';
        }
      }
    } else {
      cihazAd = 'SN: ${shipment.displaySeriNo}';
    }

    return GestureDetector(
      onTap: () => _showShipmentDetail(context, shipment),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground(context).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE9ECEF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color:
                            (shipment.yon == 2
                                    ? AppTheme.successGreen
                                    : const Color(0xFFFFAB40))
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        shipment.yon == 2
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: shipment.yon == 2
                            ? AppTheme.successGreen
                            : const Color(0xFFFFAB40),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cihazAd,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (shipment.kgt != null &&
                                  shipment.kgt!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFillColor(context),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormatUtils.formatDateTime(shipment.kgt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kargo: ${shipment.kargofirmasi?.isNotEmpty == true ? shipment.kargofirmasi : 'Bilinmiyor'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Takip No: ${shipment.takipno?.isNotEmpty == true ? shipment.takipno : 'Yok'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          if (shipment.aciklama != null && shipment.aciklama!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Not: ${shipment.aciklama}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      shipment.ucret != null
                          ? '₺${shipment.ucret!.toStringAsFixed(2)}'
                          : '-',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: shipment.sevkiyatdurumu,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: statusColor,
                            size: 16,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                          dropdownColor: AppTheme.cardBackground(context),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Hazırlanıyor'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Gönderildi'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Teslim Edildi'),
                            ),
                            DropdownMenuItem(value: 4, child: Text('İade')),
                          ],
                          onChanged: (newVal) {
                            if (newVal != null &&
                                newVal != shipment.sevkiyatdurumu) {
                              _updateStatus(shipment, newVal);
                            }
                          },
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
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFFFF9800); // Hazırlanıyor (Orange)
      case 2:
        return AppTheme.accentCyan; // Gönderildi (Cyan)
      case 3:
        return AppTheme.successGreen; // Teslim Edildi (Green)
      case 4:
        return AppTheme.accentPink; // İade (Red)
      default:
        return AppTheme.textHint(context);
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: AppTheme.accentPink.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadShipments,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor(context),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  void _showAddShipmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddShipmentSheet(
        onShipmentAdded: () {
          _loadShipments();
        },
      ),
    );
  }

  void _showShipmentDetail(BuildContext context, SevkiyatModel shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShipmentDetailSheet(
        shipment: shipment,
        onUpdated: (updated) {
          setState(() {
            final idx = _allShipments.indexWhere((s) => s.id == updated.id);
            if (idx != -1) {
              _allShipments[idx] = updated;
            }
          });
        },
        onDeleted: (deletedId) {
          setState(() {
            _allShipments.removeWhere((s) => s.id == deletedId);
          });
        },
      ),
    );
  }
}
