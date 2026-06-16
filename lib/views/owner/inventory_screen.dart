/// InventoryScreen - Inventory management for UMKM owners.
///
/// Displays a list of inventory items with real-time updates,
/// search/filter functionality, low stock indicators, and
/// CRUD operations via [InventoryViewModel].
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/models/inventory_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/inventory_view_model.dart';

/// Inventory management screen with search, filter, and CRUD.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  void _loadItems() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId != null) {
      context.read<InventoryViewModel>().loadItems(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get unique categories from items.
  List<String> _getCategories(List<InventoryModel> items) {
    final categories = items.map((i) => i.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Filter items by search query and category.
  List<InventoryModel> _getFilteredItems(List<InventoryModel> items) {
    var filtered = items;

    if (_selectedCategory != 'Semua') {
      filtered = filtered.where((i) => i.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((i) =>
              i.productName.toLowerCase().contains(query) ||
              i.category.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryVM = context.watch<InventoryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(inventoryVM),
          _buildSearchBar(inventoryVM),
          Expanded(
            child: _buildItemList(inventoryVM),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, inventoryVM),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(InventoryViewModel inventoryVM) {
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
                  Icons.inventory_2_rounded,
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
                      'Inventaris',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kelola stok barang',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (inventoryVM.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${inventoryVM.items.length} item',
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

  /// Builds the search bar and category filter.
  Widget _buildSearchBar(InventoryViewModel inventoryVM) {
    final categories = ['Semua', ..._getCategories(inventoryVM.items)];

    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
            decoration: InputDecoration(
              hintText: 'Cari item...',
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF6B7280),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      color: const Color(0xFF6B7280),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF22C55E),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          if (categories.length > 1) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;

                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF22C55E),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFE5E7EB),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the inventory items list.
  Widget _buildItemList(InventoryViewModel inventoryVM) {
    if (inventoryVM.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF22C55E),
        ),
      );
    }

    final items = _getFilteredItems(inventoryVM.items);

    if (items.isEmpty) {
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
                  Icons.inventory_2_rounded,
                  size: 64,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada item inventaris',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap tombol + untuk menambah item baru',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item.quantity <= item.minimumStock;

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context);
          },
          onDismissed: (direction) {
            inventoryVM.deleteItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.productName} dihapus'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLowStock
                    ? const Color(0xFFD97706)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showAddEditDialog(
                context,
                inventoryVM,
                existingItem: item,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFF22C55E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLowStock
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_rounded,
                        color: isLowStock
                            ? const Color(0xFFD97706)
                            : const Color(0xFF22C55E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quantity info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantity} ${item.unit}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isLowStock
                                ? const Color(0xFFD97706)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Min: ${item.minimumStock}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),

                    // Delete button
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final confirmed = await _showDeleteConfirmation(context);
                        if (confirmed == true) {
                          inventoryVM.deleteItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.productName} dihapus'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting an item.
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet for adding or editing an inventory item.
  void _showAddEditDialog(
    BuildContext context,
    InventoryViewModel inventoryVM, {
    InventoryModel? existingItem,
  }) {
    final isEditing = existingItem != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: isEditing ? existingItem.productName : '',
    );
    final categoryController = TextEditingController(
      text: isEditing ? existingItem.category : '',
    );
    final quantityController = TextEditingController(
      text: isEditing ? existingItem.quantity.toString() : '',
    );
    final minStockController = TextEditingController(
      text: isEditing ? existingItem.minimumStock.toString() : '',
    );
    final unitController = TextEditingController(
      text: isEditing ? existingItem.unit : 'pcs',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    isEditing ? 'Edit Item' : 'Tambah Item Baru',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama item wajib diisi';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Nama Item',
                      hintText: 'Contoh: Beras Organik',
                      prefixIcon: const Icon(Icons.label_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category field
                  TextFormField(
                    controller: categoryController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kategori wajib diisi';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Contoh: Bahan Baku',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Unit field
                  TextFormField(
                    controller: unitController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Satuan wajib diisi';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Satuan',
                      hintText: 'Contoh: kg, pcs, liter',
                      prefixIcon: const Icon(Icons.straighten_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity and minimum stock in a row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Angka tidak valid';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Jumlah',
                            hintText: '0',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: minStockController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Angka tidak valid';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Stok Minimum',
                            hintText: '0',
                            prefixIcon: const Icon(Icons.warning_amber_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;

                            final authVm = context.read<AuthViewModel>();
                            final userId = authVm.currentUser?.id ?? '';
                            final now = DateTime.now();

                            final item = InventoryModel(
                              id: existingItem?.id ?? '',
                              productName: nameController.text.trim(),
                              category: categoryController.text.trim(),
                              quantity: int.parse(quantityController.text),
                              minimumStock: int.parse(minStockController.text),
                              unit: unitController.text.trim(),
                              ownerId: userId,
                              createdAt: existingItem?.createdAt ?? now,
                              updatedAt: now,
                            );

                            if (isEditing) {
                              inventoryVM.updateItem(item);
                            } else {
                              inventoryVM.addItem(item);
                            }

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Item berhasil diperbarui'
                                      : 'Item berhasil ditambahkan',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEditing ? 'Simpan' : 'Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
