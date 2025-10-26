import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(AppConfig.usersEndpoint);
      if (response['success']) {
        setState(() {
          _users = response['data'] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải danh sách người dùng: $e')),
          );
        });
      }
    }
  }

  Future<void> _toggleStatus(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _api.patch('${AppConfig.usersEndpoint}/$id/toggle-status', {});
      if (response['success']) {
        messenger.showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: AppTheme.success));
        _loadUsers();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _changeRole(String id, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _api.put('${AppConfig.usersEndpoint}/$id', {'role': role});
      if (response['success']) {
        messenger.showSnackBar(const SnackBar(content: Text('Cập nhật vai trò thành công'), backgroundColor: AppTheme.success));
        _loadUsers();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteUser(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _api.delete('${AppConfig.usersEndpoint}/$id');
      if (response['success']) {
        messenger.showSnackBar(const SnackBar(content: Text('Đã xóa người dùng'), backgroundColor: AppTheme.success));
        _loadUsers();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    final fullNameController = TextEditingController(text: user['fullName'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    String selectedRole = user['role'] ?? 'receptionist';
    bool isActive = user['isActive'] == true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa người dùng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                    DropdownMenuItem(value: 'doctor', child: Text('Bác sĩ')),
                    DropdownMenuItem(value: 'receptionist', child: Text('Lễ tân')),
                    DropdownMenuItem(value: 'accountant', child: Text('Kế toán')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedRole = v);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Kích hoạt tài khoản'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
              ],
            ),
          ),
            actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  final data = {
                    'fullName': fullNameController.text.trim(),
                    'email': emailController.text.trim(),
                    'role': selectedRole,
                    'isActive': isActive,
                  };
                  await _api.put('${AppConfig.usersEndpoint}/${user['id'] ?? user['_id']}', data);
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Cập nhật người dùng thành công'), backgroundColor: AppTheme.success));
                  _loadUsers();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final u = _users[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(u['fullName'] ?? u['username'] ?? 'N/A'),
                      subtitle: Text('${u['email'] ?? ''} • ${u['role'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(u['isActive'] == true ? Icons.lock_open : Icons.lock, color: AppTheme.primaryGreen),
                            tooltip: u['isActive'] == true ? 'Khóa/ Mở khóa' : 'Mở / Khóa',
                            onPressed: () => _toggleStatus(u['id'] ?? u['_id']),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Bạn có chắc chắn muốn xóa người dùng này?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(c);
                                          _deleteUser(u['id'] ?? u['_id']);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (value == 'edit') {
                                _showEditDialog(u);
                              } else if (value.startsWith('role:')) {
                                final role = value.split(':')[1];
                                _changeRole(u['id'] ?? u['_id'], role);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa thông tin')),
                              const PopupMenuDivider(),
                              const PopupMenuItem(value: 'role:admin', child: Text('Đặt vai trò: Quản trị viên')),
                              const PopupMenuItem(value: 'role:doctor', child: Text('Đặt vai trò: Bác sĩ')),
                              const PopupMenuItem(value: 'role:receptionist', child: Text('Đặt vai trò: Lễ tân')),
                              const PopupMenuItem(value: 'role:accountant', child: Text('Đặt vai trò: Kế toán')),
                              const PopupMenuDivider(),
                              const PopupMenuItem(value: 'delete', child: Text('Xóa người dùng', style: TextStyle(color: AppTheme.error))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
