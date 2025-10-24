import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/medicine.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _searchController.addListener(_filterMedicines);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(AppConfig.medicinesEndpoint);
      if (response['success']) {
        setState(() {
          _medicines = (response['data'] as List)
              .map((json) => Medicine.fromJson(json))
              .toList();
          _filteredMedicines = _medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedicines = _medicines.where((medicine) {
        return medicine.medicineName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thuốc mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thuốc *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị (viên, hộp, chai...) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá *',
                  border: OutlineInputBorder(),
                  suffixText: 'đ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tồn kho',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  unitController.text.isEmpty ||
                  priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc')),
                );
                return;
              }

              try {
                final data = {
                  'medicineName': nameController.text.trim(),
                  'unit': unitController.text.trim(),
                  'price': double.parse(priceController.text),
                  'stockQuantity': int.tryParse(stockController.text) ?? 0,
                  if (descriptionController.text.isNotEmpty)
                    'description': descriptionController.text.trim(),
                };

                await _api.post(AppConfig.medicinesEndpoint, data);
                Navigator.pop(context);
                _loadMedicines();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm thuốc thành công'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(Medicine medicine) async {
    final nameController = TextEditingController(text: medicine.medicineName);
    final unitController = TextEditingController(text: medicine.unit);
    final priceController = TextEditingController(text: medicine.price.toString());
    final stockController = TextEditingController(text: medicine.stockQuantity.toString());
    final descriptionController = TextEditingController(text: medicine.description ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thuốc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thuốc *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá *',
                  border: OutlineInputBorder(),
                  suffixText: 'đ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tồn kho',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'medicineName': nameController.text.trim(),
                  'unit': unitController.text.trim(),
                  'price': double.parse(priceController.text),
                  'stockQuantity': int.tryParse(stockController.text) ?? 0,
                  if (descriptionController.text.isNotEmpty)
                    'description': descriptionController.text.trim(),
                };

                await _api.put('${AppConfig.medicinesEndpoint}/${medicine.id}', data);
                Navigator.pop(context);
                _loadMedicines();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật thành công'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedicine(String id) async {
    try {
      await _api.delete('${AppConfig.medicinesEndpoint}/$id');
      _loadMedicines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thuốc'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuốc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicines,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thuốc...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Medicine Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.lightGrey,
            child: Row(
              children: [
                Text(
                  'Tổng số: ${_filteredMedicines.length} thuốc',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),

          // Medicine List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMedicines.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMedicines,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredMedicines.length,
                          itemBuilder: (context, index) {
                            return _buildMedicineCard(_filteredMedicines[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm thuốc'),
        backgroundColor: AppTheme.secondaryBlue,
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: AppTheme.secondaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đơn vị: ${medicine.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStockChip(medicine),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey),
                    ),
                    Text(
                      _formatCurrency(medicine.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tồn kho',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey),
                    ),
                    Text(
                      '${medicine.stockQuantity} ${medicine.unit}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: medicine.isOutOfStock
                            ? AppTheme.error
                            : medicine.isLowStock
                                ? AppTheme.warning
                                : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (medicine.description != null) ...[
              const SizedBox(height: 12),
              Text(
                medicine.description!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(medicine),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(medicine),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChip(Medicine medicine) {
    Color color;
    String label;
    IconData icon;

    if (medicine.isOutOfStock) {
      color = AppTheme.error;
      label = 'Hết hàng';
      icon = Icons.error;
    } else if (medicine.isLowStock) {
      color = AppTheme.warning;
      label = 'Sắp hết';
      icon = Icons.warning;
    } else {
      color = AppTheme.success;
      label = 'Còn hàng';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: AppTheme.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thuốc nào',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thuốc "${medicine.medicineName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMedicine(medicine.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final amount = value.toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
}