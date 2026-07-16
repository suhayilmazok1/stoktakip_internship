import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';
import 'add_harici_alim_sheet.dart';
import 'add_seyahat_sheet.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _apiService = ApiService.instance;
  int _selectedTabIndex = 0; // 0: Dışarıdan Alımlar, 1: Seyahatler

  bool _isLoading = true;
  String? _error;

  List<HariciAlimModel> _hariciAlimList = [];
  List<SeyahatModel> _seyahatList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_selectedTabIndex == 0) {
        final list = await _apiService.haricalimListele();
        setState(() => _hariciAlimList = list);
      } else {
        final list = await _apiService.seyahatListele();
        setState(() => _seyahatList = list);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const ShimmerLoadingList()
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.accentPink),
                        ),
                      )
                    : _selectedTabIndex == 0
                    ? _buildHariciAlimList()
                    : _buildSeyahatList(),
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
            'Harici Masraflar',
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

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.inputBorderColor(context)),
        ),
        child: Row(
          children: [
            _buildTab(0, 'Dışarıdan Alımlar', Icons.shopping_bag_outlined),
            _buildTab(1, 'Seyahatler', Icons.flight_takeoff_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTabIndex != index) {
            setState(() => _selectedTabIndex = index);
            _loadData();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHariciAlimList() {
    if (_hariciAlimList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.shopping_cart_rounded,
        title: 'Harici Alım Yok',
        subtitle: 'Henüz bir harici alım kaydı eklenmemiş.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: _hariciAlimList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _hariciAlimList[index];
        return _buildHariciAlimCard(item);
      },
    );
  }

  Widget _buildHariciAlimCard(HariciAlimModel item) {
    return GestureDetector(
      onTap: () => _showAddHariciAlimSheet(existingItem: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inputBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.urunadi ?? 'İsimsiz Ürün',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.tutar != null)
                      Text(
                        '${item.tutar!.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successGreen,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.faturano != null && item.faturano!.isNotEmpty)
              _buildInfoRow(
                Icons.receipt_long_rounded,
                'Fatura: ${item.faturano}',
              ),
            if (item.alimtarihi != null && item.alimtarihi!.isNotEmpty)
              _buildInfoRow(Icons.calendar_today_rounded, item.alimtarihi!),
            if (item.adsoyad != null && item.adsoyad!.isNotEmpty)
              _buildInfoRow(
                Icons.person_rounded,
                'Satın Alan: ${item.adsoyad}',
              ),
            if (item.aciklama != null && item.aciklama!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.aciklama!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeyahatList() {
    if (_seyahatList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.flight_takeoff_rounded,
        title: 'Seyahat Kaydı Yok',
        subtitle: 'Henüz bir seyahat kaydı eklenmemiş.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: _seyahatList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _seyahatList[index];
        return _buildSeyahatCard(item);
      },
    );
  }

  Widget _buildSeyahatCard(SeyahatModel item) {
    return GestureDetector(
      onTap: () => _showAddSeyahatSheet(existingItem: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inputBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.seyahatdetayi ?? 'Detay Yok',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.tarih != null && item.tarih!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.tarih!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.arizaid != null)
              _buildInfoRow(
                Icons.build_circle_outlined,
                'Arıza ID: #${item.arizaid}',
              ),
            if (item.kisiler.isNotEmpty)
              _buildInfoRow(
                Icons.group_rounded,
                item.kisiler.map((k) => k.adsoyad).join(', '),
              ),
            if (item.tutar != null)
              _buildInfoRow(
                Icons.attach_money_rounded,
                'Tutar: ₺${item.tutar!.toStringAsFixed(2)}',
              ),
            if (item.aciklama != null && item.aciklama!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.aciklama!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet() {
    if (_selectedTabIndex == 0) {
      _showAddHariciAlimSheet();
    } else {
      _showAddSeyahatSheet();
    }
  }

  void _showAddHariciAlimSheet({HariciAlimModel? existingItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddHariciAlimSheet(existingItem: existingItem, onAdded: _loadData),
    );
  }

  void _showAddSeyahatSheet({SeyahatModel? existingItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddSeyahatSheet(existingItem: existingItem, onAdded: _loadData),
    );
  }
}
