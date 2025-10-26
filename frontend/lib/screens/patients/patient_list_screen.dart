import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/patient.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String _selectedType = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Sửa lại hàm load bệnh nhân bị lỗi cú pháp
  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(AppConfig.patientsEndpoint);
      if (response['success']) {
        final List<dynamic> data = response['data'];
        setState(() {
          _patients = data.map((json) => Patient.fromJson(json)).toList();
          _filteredPatients = _patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
          );
        });
      }
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final matchesSearch = patient.fullName.toLowerCase().contains(query) ||
            patient.phone.contains(query);
        final matchesType =
            _selectedType == 'Tất cả' || patient.patientType == _selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _changePatientType(String type) {
    setState(() {
      _selectedType = type;
      _filterPatients();
    });
  }

  Future<void> _deletePatient(String id) async {
    try {
      await _api.delete('${AppConfig.patientsEndpoint}/$id');
      _loadPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bệnh nhân thành công'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa bệnh nhân: $e')),
        );
      }
    }
  }

  void _confirmDelete(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content:
            Text('Bạn có chắc chắn muốn xóa bệnh nhân "${patient.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePatient(patient.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedType == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => _changePatientType(label),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.accentGreen,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.darkGrey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type) {
      case 'BHYT':
        color = AppTheme.secondaryBlue;
        break;
      case 'VIP':
        color = AppTheme.accentOrange;
        break;
      default:
        color = AppTheme.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 77)),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/patients/detail',
            arguments: patient.id,
          );
          if (result == true) _loadPatients();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar — white circular badge with subtle ring for a cleaner look
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 15)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Center(
                  child: Text(
                    patient.fullName.isNotEmpty
                        ? patient.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.black,
                            ),
                          ),
                        ),
                        _buildTypeChip(patient.patientType),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          patient.phone,
                          style: const TextStyle(
                            color: AppTheme.darkGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.cake, size: 16, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(patient.dateOfBirth)} (${patient.age} tuổi)',
                          style: const TextStyle(
                            color: AppTheme.darkGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (patient.gender != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            patient.gender == 'Nam'
                                ? Icons.male
                                : Icons.female,
                            size: 16,
                            color: AppTheme.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            patient.gender!,
                            style: const TextStyle(
                              color: AppTheme.darkGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              Consumer<AuthProvider>(builder: (context, auth, _) {
                final canEdit = auth.canCreatePatient;
                final canDelete = auth.canDeletePatient;
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        '/patients/edit',
                        arguments: patient,
                      ).then((result) {
                        if (result == true) _loadPatients();
                      });
                    } else if (value == 'delete') {
                      _confirmDelete(patient);
                    } else if (value == 'medical') {
                      Navigator.pushNamed(
                        context,
                        '/medical-records',
                        arguments: {'patientId': patient.id},
                      );
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[];
                    items.add(const PopupMenuItem(
                      value: 'medical',
                      child: Row(
                        children: [
                          Icon(Icons.assignment, color: AppTheme.primaryGreen),
                          SizedBox(width: 8),
                          Text('Xem hồ sơ khám'),
                        ],
                      ),
                    ));
                    if (canEdit) {
                      items.add(const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppTheme.secondaryBlue),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ));
                    }
                    if (canDelete) {
                      items.add(const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ));
                    }
                    return items;
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.grey.withValues(alpha: 128),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có bệnh nhân nào',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey.withValues(alpha: 179),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<AuthProvider>(builder: (context, auth, _) {
            if (auth.canCreatePatient) {
              return Text(
                'Nhấn nút + để thêm bệnh nhân mới',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey.withValues(alpha: 128),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bệnh nhân'),
        actions: [
          Consumer<AuthProvider>(builder: (context, auth, _) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: auth.isActive ? _loadPatients : null,
              tooltip: auth.isActive ? 'Làm mới' : 'Tài khoản chưa kích hoạt',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bệnh nhân...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả'),
                      _buildFilterChip('Thường'),
                      _buildFilterChip('BHYT'),
                      _buildFilterChip('VIP'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Patient Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.lightGrey,
            child: Row(
              children: [
                Text(
                  'Tổng số: ${_filteredPatients.length} bệnh nhân',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            return _buildPatientCard(_filteredPatients[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
        floatingActionButton: Consumer<AuthProvider>(builder: (context, auth, _) {
        if (!auth.canCreatePatient) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () async {
            FocusScope.of(context).unfocus();
            final result = await Navigator.pushNamed(context, '/patients/add');
            if (result == true) _loadPatients();
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Thêm bệnh nhân'),
        );
      }),
    );
  }
}
