import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/urun_model.dart';
import '../../models/cihaz_model.dart';
import '../../services/api_service.dart';
import '../shared/empty_state_widget.dart';
import 'product_detail_screen.dart';
import 'add_stock_sheet.dart';
import 'add_product_sheet.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String kategori;
  final List<UrunModel> urunler;
  final Map<int, CihazModel> cihazMap;
  final VoidCallback onDataChanged;

  const CategoryProductsScreen({
    super.key,
    required this.kategori,
    required this.urunler,
    required this.cihazMap,
    required this.onDataChanged,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late List<UrunModel> _currentUrunler;
  late List<UrunModel> _sortedUrunler;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUrunler = List.from(widget.urunler);
    _sortUrunler();
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
      _sortUrunler();
    });
  }

  @override
  void didUpdateWidget(covariant CategoryProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urunler != oldWidget.urunler) {
      _currentUrunler = List.from(widget.urunler);
      _sortUrunler();
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await ApiService.instance.urunListele();
      final categoryProducts = allProducts.where((p) {
        final mainProduct = p.ad.trim().isNotEmpty ? p.ad.trim() : 'İsimsiz Ürün';
        return mainProduct == widget.kategori;
      }).toList();
      
      if (!mounted) return;
      setState(() {
        _currentUrunler = categoryProducts;
        _sortUrunler();
      });
      // Üst sayfayı (ProductsScreen) güncelle
      widget.onDataChanged();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortUrunler() {
    List<UrunModel> results = [];
    if (_searchQuery.isEmpty) {
      results = List.from(_currentUrunler);
    } else {
      results = _currentUrunler.where((p) {
        final matchInCihaz = widget.cihazMap.values.any((c) {
          if (c.urunid != p.id) return false;
          return (c.serino != null && c.serino!.toLowerCase().contains(_searchQuery)) ||
              (c.ureticibarkod != null && c.ureticibarkod!.toLowerCase().contains(_searchQuery)) ||
              (c.bizimbarkod != null && c.bizimbarkod!.toLowerCase().contains(_searchQuery));
        });

        return matchInCihaz || (p.ad.toLowerCase().contains(_searchQuery)) ||
            (p.kategori != null && p.kategori!.toLowerCase().contains(_searchQuery)) ||
            (p.marka != null && p.marka!.toLowerCase().contains(_searchQuery)) ||
            (p.renk != null && p.renk!.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    _sortedUrunler = results;
    // Sıralama: Stok > 0 olanlar üstte, Stok = 0 olanlar altta. Kendi içlerinde isme göre.
    _sortedUrunler.sort((a, b) {
      final aHasStock = a.stokadedi > 0 ? 1 : 0;
      final bHasStock = b.stokadedi > 0 ? 1 : 0;
      
      if (aHasStock != bHasStock) {
        return bHasStock.compareTo(aHasStock); // 1 olanlar üstte
      }
      return a.ad.compareTo(b.ad);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddProductSheet(
              defaultKategori: widget.kategori,
              onProductAdded: _refreshData,
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Yeni Ürün Ekle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
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
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kategori,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_sortedUrunler.length} Ürün',
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inputBorderColor(context)),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: AppTheme.textPrimary(context)),
          decoration: InputDecoration(
            hintText: 'Ürün, seri no veya barkod ile ara...',
            hintStyle: TextStyle(color: AppTheme.textHint(context)),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppTheme.textSecondary(context),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppTheme.textSecondary(context),
                      size: 20,
                    ),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_sortedUrunler.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _sortedUrunler.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final urun = _sortedUrunler[index];
          final hasStock = urun.stokadedi > 0;
          return _buildTableRowCard(urun, hasStock);
        },
      ),
    );
  }

  Widget _buildTableRowCard(UrunModel urun, bool hasStock) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStock 
            ? AppTheme.primaryColor(context).withValues(alpha: 0.3)
            : AppTheme.inputBorderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showProductDetail(urun),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Kısım: Alt Model (Varyasyon) ve Stok Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (urun.kategori != null && urun.kategori!.isNotEmpty) ? urun.kategori! : urun.ad,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor(context),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasStock 
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasStock ? 'Stok: ${urun.stokadedi}' : 'Stok Yok',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasStock ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Alt Kısım: Ana Ürün ve Marka
              if (urun.kategori != null && urun.kategori!.isNotEmpty) ...[
                Text(
                  urun.ad, // Ana Kategori
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
              if (urun.marka != null && urun.marka!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  urun.marka!, // Marka
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint(context),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Alt Kısım: Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProductDetail(urun),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Detay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side: BorderSide(color: AppTheme.inputBorderColor(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddStockSheet(urun),
                      icon: const Icon(Icons.add_box_rounded, size: 16),
                      label: const Text('Stok Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primaryColor(context),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'Bu Kategoride Ürün Yok',
        subtitle: 'Bu kategoriye ait herhangi bir ürün bulunamadı.',
      ),
    );
  }

  // ─── Aksiyonlar ──────────────────────────────────────────────────

  void _showAddStockSheet(UrunModel urun) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStockSheet(
        urun: urun,
        onStockAdded: (addedQty) {
          final index = _currentUrunler.indexWhere((u) => u.id == urun.id);
          if (index != -1) {
            setState(() {
              _currentUrunler[index] = _currentUrunler[index].copyWith(
                stokadedi: _currentUrunler[index].stokadedi + addedQty,
              );
              _sortUrunler();
            });
            widget.onDataChanged();
          }
        },
      ),
    );
  }

  void _showProductDetail(UrunModel urun) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          urun: urun,
          onUpdated: (_) => _refreshData(),
          onDeleted: (_) => _refreshData(),
        ),
      ),
    );
  }
}
