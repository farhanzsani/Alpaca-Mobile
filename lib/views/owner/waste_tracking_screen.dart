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
          if (waste != null) {
            await wasteVm.updateWaste(savedWaste);
          } else {
            await wasteVm.addWaste(savedWaste);
          }
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
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
      appBar: AppBar(
        title: const Text('Pelacakan Limbah'),
        actions: [
          if (wasteVm.wasteItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${wasteVm.wasteItems.length} item',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(child: _buildBody(wasteVm)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWasteForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Limbah'),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
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
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.recycling, size: 16),
                  label: const Text('Dapat Digunakan Ulang'),
                  selected: _filterReusable == true,
                  onSelected: (selected) {
                    setState(() {
                      _filterReusable = selected ? true : null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Tidak Dapat Digunakan'),
                  selected: _filterReusable == false,
                  onSelected: (selected) {
                    setState(() {
                      _filterReusable = selected ? false : null;
                    });
                  },
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
      return const Center(child: CircularProgressIndicator());
    }

    if (wasteVm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                wasteVm.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadWaste,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
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
              Icon(
                Icons.recycling,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data limbah',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai lacak limbah bisnis Anda untuk mendukung ekonomi sirkular',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              Icon(
                Icons.filter_list_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada item yang cocok dengan filter',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadWaste(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: categoryColor.withValues(alpha: 0.15),
          child: Icon(
            _categoryIcon(waste.category),
            color: categoryColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                waste.wasteName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (waste.reusable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.recycling,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Reusable',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                '${waste.quantity} ${waste.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  categoryLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: categoryColor,
                      ),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
          color: AppColors.error,
          tooltip: 'Hapus',
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
