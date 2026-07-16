import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cihaz_model.dart';
import '../../models/urun_model.dart';
import '../../services/api_service.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';
import 'device_timeline_screen.dart';

class DeviceMovementsScreen extends StatefulWidget {
  const DeviceMovementsScreen({super.key});

  @override
  State<DeviceMovementsScreen> createState() => _DeviceMovementsScreenState();
}

class _DeviceMovementsScreenState extends State<DeviceMovementsScreen> {
  final _apiService = ApiService.instance;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  List<UrunModel> _urunler = [];
  List<CihazModel> _tumCihazlar = [];
  List<CihazModel> _filteredCihazlar = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterDevices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final urunList = await _apiService.urunListele();
      final cihazList = await _apiService.cihazListele();
      final stokHareketler = await _apiService.stokHareketListele();

      // Sadece urunler tablosunda aktif olarak var olan ürünlerin cihazlarını göster
      final activeUrunIds = urunList.map((u) => u.id).toSet();
      final allCihazlar = cihazList.where((c) => activeUrunIds.contains(c.urunid)).toList();
      allCihazlar.sort((a, b) => b.id.compareTo(a.id)); // Yeniden eskiye

      if (mounted) {
        setState(() {
          _urunler = urunList;
          _tumCihazlar = allCihazlar;
          _filteredCihazlar = allCihazlar;
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

  void _filterDevices() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredCihazlar = _tumCihazlar);
      return;
    }

    setState(() {
      _filteredCihazlar = _tumCihazlar.where((c) {
        final u = _urunler.firstWhere((urun) => urun.id == c.urunid,
            orElse: () => const UrunModel(id: -1, ad: '', stokadedi: 0));
        
        final serino = (c.serino ?? '').toLowerCase();
        final ad = u.ad.toLowerCase();
        final kat = (u.kategori ?? '').toLowerCase();
        final marka = (u.marka ?? '').toLowerCase();
        final ureticiBarkod = (c.ureticibarkod ?? '').toLowerCase();
        final bizimBarkod = (c.bizimbarkod ?? '').toLowerCase();

        return serino.contains(query) ||
               ad.contains(query) ||
               kat.contains(query) ||
               marka.contains(query) ||
               ureticiBarkod.contains(query) ||
               bizimBarkod.contains(query);
      }).toList();
    });
  }

  void _openTimeline(CihazModel cihaz) {
    final urun = _urunler.firstWhere(
      (u) => u.id == cihaz.urunid,
      orElse: () => const UrunModel(id: -1, ad: 'Sistemden Silinmiş Ürün', stokadedi: 0),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceTimelineScreen(cihaz: cihaz, urun: urun),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Arka plan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context).withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary(context), size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cihaz Hareketleri',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: TextStyle(color: AppTheme.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Ürün, seri no veya barkod ile ara...',
                  hintStyle: TextStyle(color: AppTheme.textHint(context), fontSize: 14 ),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textHint(context)),
                  suffixIcon: _searchController.text.isNotEmpty
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
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoadingList();
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Bir hata oluştu:\n$_error',
          style: const TextStyle(color: AppTheme.errorRed),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_filteredCihazlar.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.devices_rounded,
        title: 'Cihaz Bulunamadı',
        subtitle: 'Aramanızla eşleşen cihaz bulunamadı.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _filteredCihazlar.length,
      itemBuilder: (context, index) {
        final c = _filteredCihazlar[index];
        final u = _urunler.firstWhere(
          (urun) => urun.id == c.urunid,
          orElse: () => const UrunModel(id: -1, ad: 'Bilinmiyor', stokadedi: 0),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.inputBorderColor(context)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openTimeline(c),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.qr_code_rounded,
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
                            u.ad,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.displayIdentifier,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (u.kategori != null && u.kategori!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              u.kategori!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textHint(context),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
