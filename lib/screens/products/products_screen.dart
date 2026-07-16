import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/urun_model.dart';
import '../../models/cihaz_model.dart';
import '../../services/api_service.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';
import 'add_product_sheet.dart';
import 'product_detail_screen.dart';
import 'add_stock_sheet.dart';
import 'category_products_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _apiService = ApiService.instance;
  final _searchController = TextEditingController();

  List<UrunModel> _allProducts = [];
  List<CihazModel> _allDevices = [];
  List<UrunModel> _filteredProducts = [];
  Map<String, List<UrunModel>> _categories = {};

  bool _isLoading = true;
  String? _error;
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
      _filterData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productsFuture = _apiService.urunListele();
      final devicesFuture = _apiService.cihazListele(); // Fetch all devices for search

      final results = await Future.wait([productsFuture, devicesFuture]);
      
      if (!mounted) return;
      setState(() {
        _allProducts = results[0] as List<UrunModel>;
        _allDevices = results[1] as List<CihazModel>;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Veriler yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    List<UrunModel> results = [];

    if (_searchQuery.isEmpty) {
      results = List.from(_allProducts);
      
      // Ana Ürünleri (Kategorileri) grupla
      _categories.clear();
      for (var p in _allProducts) {
        final mainProduct = p.ad.trim().isNotEmpty ? p.ad.trim() : 'İsimsiz Ürün';
        _categories.putIfAbsent(mainProduct, () => []).add(p);
      }
    } else {
      // Barkod veya Seri No eşleşen cihazların urunid'leri
      final matchingUrunIds = _allDevices.where((c) {
        return (c.serino != null && c.serino!.toLowerCase().contains(_searchQuery)) ||
            (c.ureticibarkod != null && c.ureticibarkod!.toLowerCase().contains(_searchQuery)) ||
            (c.bizimbarkod != null && c.bizimbarkod!.toLowerCase().contains(_searchQuery));
      }).map((c) => c.urunid).toSet();

      // Ürün bilgilerinde veya cihaz eşleşmesinde bulunanları filtrele
      results = _allProducts.where((p) {
        final matchesProductInfo = (p.ad.toLowerCase().contains(_searchQuery)) ||
            (p.kategori != null && p.kategori!.toLowerCase().contains(_searchQuery)) ||
            (p.marka != null && p.marka!.toLowerCase().contains(_searchQuery)) ||
            (p.renk != null && p.renk!.toLowerCase().contains(_searchQuery));
        
        final matchesDevice = matchingUrunIds.contains(p.id);

        return matchesProductInfo || matchesDevice;
      }).toList();
    }

    // Sıralama: Stok > 0 olanlar üstte, Stok = 0 olanlar altta. Kendi içlerinde isme göre.
    results.sort((a, b) {
      final aHasStock = a.stokadedi > 0 ? 1 : 0;
      final bHasStock = b.stokadedi > 0 ? 1 : 0;
      
      if (aHasStock != bHasStock) {
        return bHasStock.compareTo(aHasStock); // 1 olanlar üstte
      }
      return a.ad.compareTo(b.ad);
    });

    _filteredProducts = results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductSheet(context),
        backgroundColor: AppTheme.primaryColor(context),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
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
            child: Text(
              'Ürünler',
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
      return const ShimmerLoadingList();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_searchQuery.isEmpty) {
      if (_categories.isEmpty) return _buildEmptyState();
      return _buildCategoryList();
    } else {
      if (_filteredProducts.isEmpty) return _buildEmptyState();
      return _buildTableList();
    }
  }

  Widget _buildCategoryList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _categories.keys.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final keys = _categories.keys.toList()..sort();
          final categoryName = keys[index];
          final products = _categories[categoryName]!;
          return _buildCategoryCard(categoryName, products);
        },
      ),
    );
  }

  Widget _buildCategoryCard(String categoryName, List<UrunModel> products) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inputBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                kategori: categoryName,
                urunler: products,
                cihazMap: {for (var d in _allDevices) d.id: d},
                onDataChanged: _loadData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: AppTheme.primaryColor(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${products.length} Alt Ürün',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textHint(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _filteredProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final urun = _filteredProducts[index];
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
        title: _searchQuery.isEmpty ? 'Kayıtlı Ürün Yok' : 'Sonuç Bulunamadı',
        subtitle: _searchQuery.isEmpty
            ? 'Sisteme henüz ürün eklenmemiş.\nYeni ürün tanımlayarak başlayabilirsiniz.'
            : '"$_searchQuery" aramasıyla eşleşen bir ürün veya cihaz (seri no/barkod) bulunamadı.',
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bir Hata Oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Tekrar Dene'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Aksiyonlar ──────────────────────────────────────────────────

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddProductSheet(defaultKategori: null, onProductAdded: _loadData),
    );
  }

  void _showAddStockSheet(UrunModel urun) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStockSheet(
        urun: urun,
        onStockAdded: (addedQty) => _loadData(),
      ),
    );
  }

  void _showProductDetail(UrunModel urun) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          urun: urun,
          onUpdated: (_) => _loadData(),
          onDeleted: (_) => _loadData(),
        ),
      ),
    );
  }
}
