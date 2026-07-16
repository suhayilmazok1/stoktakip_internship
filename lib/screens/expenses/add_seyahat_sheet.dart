import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

import '../../models/seyahat_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/snackbar_utils.dart';

class AddSeyahatSheet extends StatefulWidget {
  final SeyahatModel? existingItem;
  final VoidCallback onAdded;

  const AddSeyahatSheet({super.key, this.existingItem, required this.onAdded});

  @override
  State<AddSeyahatSheet> createState() => _AddSeyahatSheetState();
}

class _AddSeyahatSheetState extends State<AddSeyahatSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService.instance;

  final _detayController = TextEditingController();
  final _arizaIdController = TextEditingController();
  final _tarihController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _tutarController = TextEditingController();
  final _kisilerController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _selectedUsers = [];
  bool _isLoadingUsers = true;

  bool _isSaving = false;
  bool _isEditing = false;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingItem == null;
    _loadUsers();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _detayController.text = item.seyahatdetayi ?? '';
      _arizaIdController.text = item.arizaid?.toString() ?? '';
      _tarihController.text = item.tarih ?? '';
      _aciklamaController.text = item.aciklama ?? '';
      _tutarController.text = item.tutar?.toString() ?? '';
      _kisilerController.text = item.kisiler.map((k) => k.kullaniciid).join(',');
    }
  }

  @override
  void dispose() {
    _detayController.dispose();
    _arizaIdController.dispose();
    _tarihController.dispose();
    _aciklamaController.dispose();
    _tutarController.dispose();
    _kisilerController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _apiService.kullaniciListele();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
          
          if (widget.existingItem != null) {
            final existingIds = widget.existingItem!.kisiler.map((k) => k.kullaniciid).toList();
            _selectedUsers = _allUsers.where((u) => existingIds.contains(u.id)).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor(context),
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _tarihController.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final arizaId = int.tryParse(_arizaIdController.text.trim());
      final tutarVal = double.tryParse(_tutarController.text.trim());
      
      // Manuel girilen ID'ler veya dialogdan seçilenler _kisilerController'dan alınır
      final userIdsStr = _kisilerController.text.trim();

      if (widget.existingItem == null) {
        await _apiService.seyahatEkle(
          arizaid: arizaId,
          seyahatdetayi: _detayController.text,
          tarih: _tarihController.text,
          aciklama: _aciklamaController.text,
          tutar: tutarVal,
          kullanicilar: userIdsStr,
        );
      } else {
        await _apiService.seyahatGuncelle(
          id: widget.existingItem!.id,
          arizaid: arizaId,
          seyahatdetayi: _detayController.text,
          tarih: _tarihController.text,
          aciklama: _aciklamaController.text,
          tutar: tutarVal,
          kullanicilar: userIdsStr,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        SnackBarUtils.showTopSnackBar(context, widget.existingItem == null
                  ? 'Seyahat başarıyla eklendi!'
                  : 'Seyahat güncellendi!', isError: false);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, _error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.existingItem == null) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await _apiService.seyahatSil(widget.existingItem!.id);
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        SnackBarUtils.showTopSnackBar(context, 'Seyahat başarıyla silindi!', isError: false);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, _error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground(context).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppTheme.inputBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textHint(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
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
                            widget.existingItem == null
                                ? ('Yeni Seyahat')
                                : (_isEditing
                                      ? ('Seyahat Güncelle')
                                      : ('Seyahat Detayı')),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            widget.existingItem == null || _isEditing
                                ? ('Seyahat detaylarını girin')
                                : ('Seyahat detaylarını görüntüleyin'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.existingItem != null && !_isEditing) ...[
                      IconButton(
                        onPressed: _isDeleting ? null : _delete,
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.errorRed,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        color: AppTheme.errorRed,
                        tooltip: 'Sil',
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_outlined),
                        color: AppTheme.textPrimary(context),
                        tooltip: 'Düzenle',
                      ),
                    ] else if (widget.existingItem != null && _isEditing) ...[
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Seyahat Detayı *',
                            controller: _detayController,
                            icon: Icons.map_outlined,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Zorunlu alan'
                                : null,
                          ),
                          _buildUserSelectField(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Manuel Personel ID (Seçim ile otomatik dolar)',
                            controller: _kisilerController,
                            icon: Icons.edit_note_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Tutar (₺)',
                            controller: _tutarController,
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                label: 'Seyahat Tarihi',
                                controller: _tarihController,
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Bağlı Arıza ID (Varsa)',
                            controller: _arizaIdController,
                            icon: Icons.build_circle_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Açıklama',
                            controller: _aciklamaController,
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              if (widget.existingItem != null) ...[
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _delete,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentPink
                                            .withValues(alpha: 0.1),
                                        foregroundColor: AppTheme.accentPink,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Icon(Icons.delete_rounded),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor(
                                        context,
                                      ),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Kaydet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppTheme.textHint(context), size: 20)
                : null,
            filled: true,
            fillColor: AppTheme.inputFillColor(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.inputBorderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.inputBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryColor(context)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.accentPink),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
  Widget _buildUserSelectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seyahate Katılanlar',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showUserSelectionDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inputFillColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.inputBorderColor(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.group_outlined, color: AppTheme.textHint(context), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingUsers
                      ? Text('Kullanıcılar yükleniyor...', style: TextStyle(color: AppTheme.textHint(context)))
                      : Text(
                          _selectedUsers.isEmpty 
                              ? 'Personel Seçiniz' 
                              : _selectedUsers.map((u) => u.adsoyad).join(', '),
                          style: TextStyle(
                            color: _selectedUsers.isEmpty 
                                ? AppTheme.textHint(context) 
                                : AppTheme.textPrimary(context),
                            fontSize: 15,
                          ),
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: AppTheme.textHint(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showUserSelectionDialog() {
    if (_allUsers.isEmpty) {
      SnackBarUtils.showTopSnackBar(context, 'Seçilecek personel bulunamadı.', isError: true);
      return;
    }

    final tempSelected = List<UserModel>.from(_selectedUsers);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Personel Seçimi', style: TextStyle(color: AppTheme.textPrimary(context))),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final u = _allUsers[index];
                    final isSelected = tempSelected.contains(u);
                    return CheckboxListTile(
                      title: Text(u.adsoyad, style: TextStyle(color: AppTheme.textPrimary(context))),
                      subtitle: Text(u.yetki, style: TextStyle(color: AppTheme.textSecondary(context))),
                      value: isSelected,
                      activeColor: AppTheme.primaryColor(context),
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            tempSelected.add(u);
                          } else {
                            tempSelected.remove(u);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal', style: TextStyle(color: AppTheme.textHint(context))),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedUsers = List.from(tempSelected);
                      _kisilerController.text = _selectedUsers.map((u) => u.id).join(',');
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
