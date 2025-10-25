import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/service.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(AppConfig.servicesEndpoint);
      if (response['success']) {
        setState(() {
          _services = (response['data'] as List)
              .map((json) => Service.fromJson(json))
              .toList();
          _filteredServices = _services;
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

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredServices = _services.where((service) {
        final matchesSearch = service.serviceName.toLowerCase().contains(query);
        final matchesActive = _showInactive || service.isActive;
        return matchesSearch && matchesActive;
      }).toList();
    });
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final departmentController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isActive = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm dịch vụ mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên dịch vụ *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá dịch vụ *',
                    border: OutlineInputBorder(),
                    suffixText: 'đ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Khoa/Phòng',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Đang hoạt động'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() => isActive = value);
                  },
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
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                  );
                  return;
                }

                try {
                  final data = {
                    'serviceName': nameController.text.trim(),
                    'price': double.parse(priceController.text),
                    'isActive': isActive,
                    if (departmentController.text.isNotEmpty)
                      'department': departmentController.text.trim(),
                    if (descriptionController.text.isNotEmpty)
                      'description': descriptionController.text.trim(),
                  };

                  await _api.post(AppConfig.servicesEndpoint, data);
                  Navigator.pop(context);
                  _loadServices();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thêm dịch vụ thành công'),
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
      ),
    );
  }

  Future<void> _showEditDialog(Service service) async {
    final nameController = TextEditingController(text: service.serviceName);
    final priceController = TextEditingController(text: service.price.toString());
    final departmentController = TextEditingController(text: service.department ?? '');
    final descriptionController = TextEditingController(text: service.description ?? '');
    bool isActive = service.isActive;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa dịch vụ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên dịch vụ *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá dịch vụ *',
                    border: OutlineInputBorder(),
                    suffixText: 'đ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Khoa/Phòng',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Đang hoạt động'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() => isActive = value);
                  },
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
                    'serviceName': nameController.text.trim(),
                    'price': double.parse(priceController.text),
                    'isActive': isActive,
                    if (departmentController.text.isNotEmpty)
                      'department': departmentController.text.trim(),
                    if (descriptionController.text.isNotEmpty)
                      'description': descriptionController.text.trim(),
                  };

                  await _api.put('${AppConfig.servicesEndpoint}/${service.id}', data);
                  Navigator.pop(context);
                  _loadServices();
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
      ),
    );
  }

  Future<void> _deleteService(String id) async {
    try {
      await _api.delete('${AppConfig.servicesEndpoint}/$id');
      _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa dịch vụ'),
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
        title: const Text('Quản lý dịch vụ'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
                _filterServices();
              });
            },
            tooltip: _showInactive ? 'Ẩn dịch vụ ngưng hoạt động' : 'Hiện tất cả',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm dịch vụ...',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.lightGrey,
            child: Row(
              children: [
                Text(
                  'Tổng số: ${_filteredServices.length} dịch vụ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServices.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadServices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(_filteredServices[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm dịch vụ'),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
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
                    color: service.isActive 
                        ? AppTheme.primaryGreen.withValues(alpha: 26)
                        : AppTheme.grey.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: service.isActive ? AppTheme.primaryGreen : AppTheme.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (service.department != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.department!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(service.isActive),
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
                      'Giá dịch vụ',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey),
                    ),
                    Text(
                      _formatCurrency(service.price),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (service.description != null) ...[
              const SizedBox(height: 12),
              Text(
                service.description!,
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
                  onPressed: () => _showEditDialog(service),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(service),
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

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.success.withValues(alpha: 26)
            : AppTheme.grey.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? AppTheme.success.withValues(alpha: 77)
              : AppTheme.grey.withValues(alpha: 77),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? AppTheme.success : AppTheme.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Hoạt động' : 'Ngưng',
            style: TextStyle(
              color: isActive ? AppTheme.success : AppTheme.grey,
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
            Icons.medical_services_outlined,
            size: 80,
            color: AppTheme.grey.withValues(alpha: 128),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dịch vụ nào',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey.withValues(alpha: 179),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa dịch vụ "${service.serviceName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(service.id!);
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