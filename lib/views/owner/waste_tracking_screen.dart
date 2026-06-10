/// Waste tracking screen for business owners.
///
/// Manages waste resources for the circular economy feature,
/// including categorization, filtering, and identification of
/// reusable materials.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/models/waste_resource_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/waste_view_model.dart';

/// Screen for tracking and managing waste resources.
///
/// Features:
/// - List of waste resources
/// - FAB to add new waste entry
/// - Each item shows: name, quantity, category, reusable badge
/// - Filter by category
/// - Filter by reusable status
/// - Add/Edit bottom sheet
class WasteTrackingScreen extends StatefulWidget {
  /// Creates a [WasteTrackingScreen].
  const WasteTrackingScreen({super.key});

  @override
  State<WasteTrackingScreen> createState() => _WasteTrackingScreenState();
}

class _WasteTrackingScreenState extends State<WasteTrackingScreen> {
  String? _selectedCategory;
  bool? _filterReusable;

  static const _categories = [
    'organic',
    'packaging',
    'byproduct',
    'chemical',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWaste();
    });
  }

  void _loadWaste() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId != null) {
      context.read<WasteViewModel>().loadWaste(userId);
    }
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'organic':
        return 'Organik';
      case 'packaging':
        return 'Kemasan';
      case 'byproduct':
        return 'Produk Sampingan';
      case 'chemical':
        return 'Kimia';
      default:
        return 'Lainnya';
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'organic':
        return AppColors.success;
      case 'packaging':
        return AppColors.info;
      case 'byproduct':
        return AppColors.tertiary;
      case 'chemical':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }

  List<WasteResourceModel> _applyFilters(List<WasteResourceModel> items) {
    var filtered = items;

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((w) =>
              w.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .toList();
    }

    if (_filterReusable != null) {
      filtered =
          filtered.where((w) => w.reusable == _filterReusable).toList();
    }

    return filtered;
  }

  void _openWasteForm({WasteResourceModel? waste}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WasteFormSheet(
        waste: waste,
        onSave: (savedWaste) async {
          final wasteVm = context.read<WasteViewModel>();
          final authVm = context.read<AuthViewModel>();
          final userId = authVm.currentUser?.id ?? '';
          
          if (waste != null) {
            await wasteVm.updateWaste(savedWaste);
          } else {
            await wasteVm.addWaste(savedWaste);
          }
          
          // Reload waste list
          await wasteVm.loadWaste(userId);
          
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _confirmDelete(WasteResourceModel waste) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Limbah'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${waste.wasteName}"?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<WasteViewModel>().deleteWaste(waste.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wasteVm = context.watch<WasteViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(wasteVm),
          _buildFilters(context),
          Expanded(child: _buildBody(wasteVm)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWasteForm(),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Limbah'),
      ),
    );
  }

  Widget _buildHeader(WasteViewModel wasteVm) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: Color(0xFF86EFAC),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelacakan Limbah',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kelola limbah bisnis',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (wasteVm.wasteItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${wasteVm.wasteItems.length} item',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF22C55E),
                  side: BorderSide(
                    color: _selectedCategory == null
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFE5E7EB),
                  ),
                  labelStyle: TextStyle(
                    color: _selectedCategory == null
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_categoryLabel(category)),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: _categoryColor(category).withValues(alpha: 0.15),
                      checkmarkColor: _categoryColor(category),
                      side: BorderSide(
                        color: _selectedCategory == category
                            ? _categoryColor(category)
                            : const Color(0xFFE5E7EB),
                      ),
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? _categoryColor(category)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: _selectedCategory == category ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Reusable filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua Status'),
                  selected: _filterReusable == null,
                  onSelected: (_) {
                    setState(() => _filterReusable = null);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF22C55E),
                  side: BorderSide(
                    color: _filterReusable == null
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFE5E7EB),
                  ),
                  labelStyle: TextStyle(
                    color: _filterReusable == null
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: _filterReusable == null ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.recycling_rounded,
                    size: 16,
                    color: _filterReusable == true
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF6B7280),
                  ),
                  label: const Text('Dapat Digunakan Ulang'),
                  selected: _filterReusable == true,
                  onSelected: (selected) {
                    setState(() {
                      _filterReusable = selected ? true : null;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF22C55E),
                  side: BorderSide(
                    color: _filterReusable == true
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFE5E7EB),
                  ),
                  labelStyle: TextStyle(
                    color: _filterReusable == true
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: _filterReusable == true ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: _filterReusable == false
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                  ),
                  label: const Text('Tidak Dapat Digunakan'),
                  selected: _filterReusable == false,
                  onSelected: (selected) {
                    setState(() {
                      _filterReusable = selected ? false : null;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFFDC2626),
                  side: BorderSide(
                    color: _filterReusable == false
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFE5E7EB),
                  ),
                  labelStyle: TextStyle(
                    color: _filterReusable == false
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: _filterReusable == false ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WasteViewModel wasteVm) {
    if (wasteVm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF22C55E),
        ),
      );
    }

    if (wasteVm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                wasteVm.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadWaste,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    if (wasteVm.wasteItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  size: 64,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada data limbah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mulai lacak limbah bisnis Anda untuk\nmendukung ekonomi sirkular',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredItems = _applyFilters(wasteVm.wasteItems);

    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.filter_list_off_rounded,
                  size: 64,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tidak ada item yang cocok dengan filter',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF22C55E),
      onRefresh: () async => _loadWaste(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final waste = filteredItems[index];
          return _WasteListItem(
            waste: waste,
            categoryLabel: _categoryLabel(waste.category),
            categoryColor: _categoryColor(waste.category),
            onTap: () => _openWasteForm(waste: waste),
            onDelete: () => _confirmDelete(waste),
          );
        },
      ),
    );
  }
}

/// A list item widget displaying waste resource information.
class _WasteListItem extends StatelessWidget {
  const _WasteListItem({
    required this.waste,
    required this.categoryLabel,
    required this.categoryColor,
    required this.onTap,
    required this.onDelete,
  });

  final WasteResourceModel waste;
  final String categoryLabel;
  final Color categoryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(waste.category),
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            waste.wasteName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (waste.reusable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.recycling_rounded,
                                  size: 12,
                                  color: Color(0xFF22C55E),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reusable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${waste.quantity} ${waste.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            categoryLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'organic':
        return Icons.eco_outlined;
      case 'packaging':
        return Icons.inventory_2_outlined;
      case 'byproduct':
        return Icons.science_outlined;
      case 'chemical':
        return Icons.warning_amber_outlined;
      default:
        return Icons.delete_outline;
    }
  }
}

/// Bottom sheet form for adding or editing a waste resource.
class _WasteFormSheet extends StatefulWidget {
  const _WasteFormSheet({
    this.waste,
    required this.onSave,
  });

  final WasteResourceModel? waste;
  final Future<void> Function(WasteResourceModel waste) onSave;

  @override
  State<_WasteFormSheet> createState() => _WasteFormSheetState();
}

class _WasteFormSheetState extends State<_WasteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'organic';
  bool _isReusable = false;
  bool _isSaving = false;

  static const _categories = [
    'organic',
    'packaging',
    'byproduct',
    'chemical',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.waste != null) {
      _nameController.text = widget.waste!.wasteName;
      _quantityController.text = widget.waste!.quantity.toString();
      _unitController.text = widget.waste!.unit;
      _notesController.text = widget.waste!.processingNotes ?? '';
      _selectedCategory = widget.waste!.category;
      _isReusable = widget.waste!.reusable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'organic':
        return 'Organik';
      case 'packaging':
        return 'Kemasan';
      case 'byproduct':
        return 'Produk Sampingan';
      case 'chemical':
        return 'Kimia';
      default:
        return 'Lainnya';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id ?? '';
    final now = DateTime.now();

    final waste = WasteResourceModel(
      id: widget.waste?.id ?? '',
      wasteName: _nameController.text.trim(),
      quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
      unit: _unitController.text.trim(),
      category: _selectedCategory,
      reusable: _isReusable,
      processingNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      ownerId: userId,
      createdAt: widget.waste?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.onSave(waste);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.waste != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Text(
                    isEditing ? 'Edit Limbah' : 'Tambah Limbah',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 24),

                // Waste name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Limbah',
                    hintText: 'Masukkan nama limbah',
                    prefixIcon: Icon(Icons.eco_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama limbah wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity and unit row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          hintText: '0',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final qty = double.tryParse(value.trim());
                          if (qty == null || qty < 0) {
                            return 'Jumlah tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          hintText: 'kg',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'other',
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(c)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Reusable toggle
                SwitchListTile(
                  title: const Text('Dapat Digunakan Ulang'),
                  subtitle: Text(
                    _isReusable
                        ? 'Limbah ini dapat diproses ulang atau dimanfaatkan'
                        : 'Limbah ini tidak dapat digunakan kembali',
                  ),
                  value: _isReusable,
                  onChanged: (value) {
                    setState(() => _isReusable = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    _isReusable ? Icons.recycling : Icons.delete_outline,
                    color: _isReusable ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),

                // Processing notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Pemrosesan (Opsional)',
                    hintText: 'Cara memproses atau memanfaatkan limbah ini',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Save button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isEditing ? 'Perbarui Limbah' : 'Simpan Limbah'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
