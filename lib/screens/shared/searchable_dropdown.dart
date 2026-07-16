import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final String Function(T) itemSearchString;
  final void Function(T) onChanged;
  final String hint;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.itemLabel,
    required this.itemSearchString,
    required this.onChanged,
    required this.hint,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  void _openSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchBottomSheet<T>(
        items: widget.items,
        selectedItem: widget.selectedItem,
        itemLabel: widget.itemLabel,
        itemSearchString: widget.itemSearchString,
        onSelected: (item) {
          widget.onChanged(item);
          Navigator.pop(context);
        },
        hint: widget.hint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedItem != null;

    return GestureDetector(
      onTap: widget.items.isNotEmpty ? _openSelectionSheet : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.inputBorderColor(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasSelection ? widget.itemLabel(widget.selectedItem as T) : widget.hint,
                style: TextStyle(
                  fontSize: 15,
                  color: hasSelection
                      ? AppTheme.textPrimary(context)
                      : AppTheme.textHint(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: AppTheme.textHint(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBottomSheet<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final String Function(T) itemSearchString;
  final void Function(T) onSelected;
  final String hint;

  const _SearchBottomSheet({
    required this.items,
    this.selectedItem,
    required this.itemLabel,
    required this.itemSearchString,
    required this.onSelected,
    required this.hint,
  });

  @override
  State<_SearchBottomSheet<T>> createState() => _SearchBottomSheetState<T>();
}

class _SearchBottomSheetState<T> extends State<_SearchBottomSheet<T>> {
  final _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
      });
      return;
    }

    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.itemSearchString(item).toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Height bound to 80% of screen height
    final sheetHeight = MediaQuery.of(context).size.height * 0.8;

    return Material(
      color: AppTheme.cardBackground(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: sheetHeight,
      child: Column(
        children: [
          // Header handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              widget.hint,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
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
          ),
          
          // List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'Sonuç bulunamadı.',
                      style: TextStyle(color: AppTheme.textHint(context)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedItem;
                      
                      return ListTile(
                        onTap: () => widget.onSelected(item),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected 
                            ? AppTheme.primaryColor(context).withValues(alpha: 0.1)
                            : Colors.transparent,
                        title: Text(
                          widget.itemLabel(item),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected 
                            ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor(context))
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      )
    );
    
  }
}
