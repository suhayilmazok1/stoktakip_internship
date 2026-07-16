import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/montaj_model.dart';
import '../../models/cihaz_model.dart';
import '../../models/urun_model.dart';
import '../../services/api_service.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';
import 'add_assembly_sheet.dart';
import '../../core/utils/snackbar_utils.dart';

class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key});

  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen> {
  final _apiService = ApiService.instance;

  bool _isLoading = true;
  String? _error;
  List<MontajModel> _montajList = [];
  Map<int, CihazModel> _cihazMap = {};
  Map<int, UrunModel> _urunMap = {};

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final montajlar = await _apiService.montajListele(gecmisdahil: false);
      final hareketler = await _apiService.stokHareketListele();
      final cihazlar = await _apiService.cihazListele();
      final urunler = await _apiService.urunListele();

      if (mounted) {
        _cihazMap = {for (var c in cihazlar) c.id: c};
        _urunMap = {for (var u in urunler) u.id: u};
      }

      final tamirHareketleri = hareketler
          .where((h) => h.aciklama != null && h.aciklama!.startsWith('Tamir/Bakım Notu:'))
          .toList();

      for (var h in tamirHareketleri) {
        final c = cihazlar.where((x) => x.id == h.cihazid).firstOrNull;
        if (c == null) continue;
        final u = urunler.where((x) => x.id == c.urunid).firstOrNull;
        
        montajlar.add(MontajModel(
          id: -h.id, // fake id
          anacihazid: h.cihazid,
          anaserino: c.serino,
          anaurunad: u?.ad ?? 'Bilinmeyen Ürün',
          bilesencihazid: 0,
          bilesenserino: null,
          bilesenurunad: 'Sadece Bakım / Tamir',
          aciklama: h.aciklama,
          sokulmetarihi: null,
        ));
      }

      setState(() => _montajList = montajlar);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sokMontaj(MontajModel montaj) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Bileşeni Sök'),
        content: Text(
          '${montaj.bilesenurunad ?? 'Bileşen'} (SN: ${montaj.displayBilesenSeriNo}) parçasını sökmek istediğinize emin misiniz?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sök'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.montajSok(
        bilesencihazid: montaj.bilesencihazid,
        yenicihazdurumu: 1, // Sökülünce Müsait (1) duruma döner
      );
      await _loadData(); // Yenile
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showTopSnackBar(context, 'Hata: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAssemblySheet(
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGradient(context).colors.first,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const ShimmerLoadingList()
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorRed),
                        ),
                      )
                    : _buildMontajList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppTheme.primaryColor(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          Text(
            'Montaj / Tamir',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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

  List<MontajModel> get _displayedMontajlar {
    if (_searchQuery.isEmpty) return _montajList;

    return _montajList.where((m) {
      final anaCihaz = _cihazMap[m.anacihazid];
      final bilesenCihaz = _cihazMap[m.bilesencihazid];

      return (m.anaurunad != null && m.anaurunad!.toLowerCase().contains(_searchQuery)) ||
             (m.bilesenurunad != null && m.bilesenurunad!.toLowerCase().contains(_searchQuery)) ||
             (m.anaserino != null && m.anaserino!.toLowerCase().contains(_searchQuery)) ||
             (m.bilesenserino != null && m.bilesenserino!.toLowerCase().contains(_searchQuery)) ||
             (anaCihaz?.ureticibarkod != null && anaCihaz!.ureticibarkod!.toLowerCase().contains(_searchQuery)) ||
             (anaCihaz?.bizimbarkod != null && anaCihaz!.bizimbarkod!.toLowerCase().contains(_searchQuery)) ||
             (bilesenCihaz?.ureticibarkod != null && bilesenCihaz!.ureticibarkod!.toLowerCase().contains(_searchQuery)) ||
             (bilesenCihaz?.bizimbarkod != null && bilesenCihaz!.bizimbarkod!.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Widget _buildMontajList() {
    final list = _displayedMontajlar;
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.hardware_rounded,
        title: 'Kayıt Bulunamadı',
        subtitle: 'Aktif montaj veya tamir işlemi bulunmuyor.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final m = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.inputBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ana Cihaz Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF97316,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.computer_rounded,
                            color: Color(0xFFF97316),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ana Cihaz',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary(context),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                m.anaurunad ?? 'Cihaz Adı Yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              Text(
                                'SN: ${m.displayAnaSeriNo}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    // Bağlı Bileşen
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFBBF24,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            m.bilesencihazid == 0 ? Icons.home_repair_service_rounded : Icons.memory_rounded,
                            color: const Color(0xFFFBBF24),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bileşen',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary(context),
                                ),
                              ),
                              Text(
                                m.bilesenurunad ?? 'Bileşen Adı Yok',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              Text(
                                'SN: ${m.displayBilesenSeriNo}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (m.bilesencihazid != 0)
                          IconButton(
                            onPressed: () => _sokMontaj(m),
                            icon: const Icon(
                              Icons.link_off_rounded,
                              color: AppTheme.errorRed,
                            ),
                            tooltip: 'Bileşeni Sök',
                          ),
                      ],
                    ),
                    if (m.aciklama != null && m.aciklama!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.aciklama!,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary(context),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
