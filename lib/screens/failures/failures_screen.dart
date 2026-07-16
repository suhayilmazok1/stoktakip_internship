import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ariza_model.dart';
import '../../models/cihaz_model.dart';
import '../../models/urun_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/date_utils.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';
import 'add_failure_sheet.dart';
import 'failure_detail_sheet.dart';

class FailuresScreen extends StatefulWidget {
  const FailuresScreen({super.key});

  @override
  State<FailuresScreen> createState() => _FailuresScreenState();
}

class _FailuresScreenState extends State<FailuresScreen> {
  final _apiService = ApiService.instance;

  List<ArizaModel> _allFailures = [];
  Map<int, CihazModel> _cihazMap = {};
  Map<int, UrunModel> _urunMap = {};
  bool _isLoading = true;
  String? _error;

  int _selectedFilter = 0; // 0: Tümü, 1: Açık, 2: Kapalı
  
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFailures();
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

  Future<void> _loadFailures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.arizaListele(),
        _apiService.cihazListele(),
        _apiService.urunListele(),
      ]);

      final failureList = results[0] as List<dynamic>;
      final cihazList = results[1] as List<dynamic>;
      final urunList = results[2] as List<dynamic>;

      if (mounted) {
        setState(() {
          _cihazMap = {for (var c in cihazList) c.id: c as CihazModel};
          _urunMap = {for (var u in urunList) u.id: u as UrunModel};

          final list = List<ArizaModel>.from(failureList);
          _allFailures = list..sort((a, b) => b.id.compareTo(a.id));
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

  List<ArizaModel> get _displayedFailures {
    List<ArizaModel> filtered = _allFailures;
    
    if (_selectedFilter != 0) {
      filtered = filtered.where((f) => f.arizadurumu == _selectedFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((f) {
        final cihaz = _cihazMap[f.cihazid];
        final urun = cihaz != null ? _urunMap[cihaz.urunid] : null;

        return (f.urunad != null && f.urunad!.toLowerCase().contains(_searchQuery)) ||
               (f.serino != null && f.serino!.toLowerCase().contains(_searchQuery)) ||
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
              _buildFilters(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFailureSheet(context),
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
              'Arızalar',
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

  Widget _buildFilters() {
    final filters = [
      {'id': 0, 'label': 'Tümü'},
      {'id': 1, 'label': 'Açık'},
      {'id': 2, 'label': 'Kapalı'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoadingList();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final list = _displayedFailures;

    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.build_rounded,
        title: 'Kayıt Bulunamadı',
        subtitle: 'Gösterilecek arıza kaydı bulunmuyor.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildFailureCard(list[index]),
    );
  }

  Widget _buildFailureCard(ArizaModel failure) {
    final isAcik = failure.isAcik;
    final statusColor = isAcik ? AppTheme.accentPink : AppTheme.successGreen;

    String cihazAd = 'ID:${failure.cihazid} (Anonim)';
    final cihaz = _cihazMap[failure.cihazid];
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
    } else {
      cihazAd = 'SN: ${failure.displaySeriNo}';
    }

    return GestureDetector(
      onTap: () => _showFailureDetail(context, failure),
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
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAcik
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arıza ID: ${failure.id}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cihazAd,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            failure.aciklama?.isNotEmpty == true
                                ? failure.aciklama!
                                : 'Açıklama girilmemiş.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary(context),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      failure.tamamlanmatarihi != null
                          ? 'Kapanış: ${DateFormatUtils.formatDateTime(failure.tamamlanmatarihi)}'
                          : 'Açılış: ${DateFormatUtils.formatDateTime(failure.kgt)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textHint(context),
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        failure.durumAdi,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFailures,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  void _showAddFailureSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFailureSheet(
        onFailureAdded: () {
          _loadFailures();
        },
      ),
    );
  }

  void _showFailureDetail(BuildContext context, ArizaModel failure) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FailureDetailSheet(
        failure: failure,
        onUpdated: (updated) {
          setState(() {
            final idx = _allFailures.indexWhere((f) => f.id == updated.id);
            if (idx != -1) {
              _allFailures[idx] = updated;
            }
          });
        },
        onDeleted: (deletedId) {
          setState(() {
            _allFailures.removeWhere((f) => f.id == deletedId);
          });
        },
      ),
    );
  }
}
