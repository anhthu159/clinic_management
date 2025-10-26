import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/appointment.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Appointment> _allAppointments = [];
  List<Appointment> _todayAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final allResponse = await _api.get(AppConfig.appointmentsEndpoint);
      final todayResponse =
          await _api.get('${AppConfig.appointmentsEndpoint}/today');

      if (allResponse['success'] && todayResponse['success']) {
        setState(() {
          _allAppointments = (allResponse['data'] as List)
              .map((json) => Appointment.fromJson(json))
              .toList();
          _todayAppointments = (todayResponse['data'] as List)
              .map((json) => Appointment.fromJson(json))
              .toList();
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

  Future<void> _updateAppointmentStatus(String id, String status) async {
    try {
      await _api.patch(
        '${AppConfig.appointmentsEndpoint}/$id/status',
        {'status': status},
      );
      _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái'),
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

  Future<void> _deleteAppointment(String id) async {
    try {
      await _api.delete('${AppConfig.appointmentsEndpoint}/$id');
      _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa lịch hẹn'),
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

  void _confirmDeleteAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa lịch hẹn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (appointment.id != null) _deleteAppointment(appointment.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (appointment.id != null) _updateAppointmentStatus(appointment.id!, 'Hủy');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hủy lịch hẹn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch hẹn'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Tất cả'),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(builder: (context, auth, _) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: auth.isActive ? _loadAppointments : null,
              tooltip: auth.isActive ? 'Làm mới' : 'Tài khoản chưa kích hoạt',
            );
          }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildAllTab(),
              ],
            ),
      floatingActionButton: Consumer<AuthProvider>(builder: (context, auth, _) {
        if (!auth.canCreateAppointment) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/appointments/add');
            if (result == true) {
              _loadAppointments();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Đặt lịch hẹn'),
        );
      }),
    );
  }

  Widget _buildTodayTab() {
    if (_todayAppointments.isEmpty) {
      return _buildEmptyState('Không có lịch hẹn nào hôm nay');
    }

    final grouped = <String, List<Appointment>>{};
    for (var apt in _todayAppointments) {
      grouped.putIfAbsent(apt.appointmentTime, () => []).add(apt);
    }

    final sortedTimes = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedTimes.length,
      itemBuilder: (context, index) {
        final time = sortedTimes[index];
        final appointments = grouped[time]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${appointments.length} lịch',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...appointments.map((apt) => _buildAppointmentCard(apt)),
          ],
        );
      },
    );
  }

  Widget _buildAllTab() {
    if (_allAppointments.isEmpty) {
      return _buildEmptyState('Chưa có lịch hẹn nào');
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _allAppointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(_allAppointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin bệnh nhân
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        appointment.patientInfo?.fullName.isNotEmpty == true
                            ? appointment.patientInfo!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientInfo?.fullName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 14, color: AppTheme.grey),
                            const SizedBox(width: 4),
                            Text(
                              appointment.patientInfo?.phone ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(appointment.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Chi tiết lịch hẹn
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(Icons.calendar_today, 'Ngày',
                        dateFormat.format(appointment.appointmentDate)),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                        Icons.access_time, 'Giờ', appointment.appointmentTime),
                  ),
                ],
              ),
              if (appointment.doctorName != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Bác sĩ', appointment.doctorName!),
              ],
              if (appointment.roomNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.meeting_room, 'Phòng', appointment.roomNumber!),
              ],
              if (appointment.reason != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.description, 'Lý do', appointment.reason!),
              ],

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (appointment.status == 'Chờ khám') ...[
                    Consumer<AuthProvider>(builder: (context, auth, _) {
                      final List<Widget> actions = [];
                      // Only doctors and admins (and only if account is active) can mark as visited
                      if ((auth.isDoctor || auth.isAdmin) && auth.isActive) {
                        actions.add(TextButton.icon(
                          onPressed: () => _updateAppointmentStatus(appointment.id!, 'Đã khám'),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Đã khám'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.success,
                          ),
                        ));
                        actions.add(const SizedBox(width: 8));
                      }
                      // Allow cancel if user has cancel permission
                      if (auth.canCancelAppointment) {
                        actions.add(TextButton.icon(
                          onPressed: () => _confirmCancelAppointment(appointment),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Hủy'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.error,
                          ),
                        ));
                      }

                      return Row(children: actions);
                    }),
                  ],
                  const SizedBox(width: 8),
                  Consumer<AuthProvider>(builder: (context, auth, _) {
                    if (!auth.canEditAppointment && !auth.canCancelAppointment && !( (auth.isDoctor || auth.isAdmin) && auth.isActive)) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showAppointmentMenu(appointment),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Hiển thị trạng thái rỗng
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppTheme.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppTheme.darkGrey),
          ),
        ],
      ),
    );
  }

  // Hiển thị chip trạng thái lịch hẹn
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Đã khám':
        color = AppTheme.success;
        break;
      case 'Hủy':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.primaryGreen;
    }
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // Hiển thị một dòng thông tin
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Hiển thị menu tuỳ chọn cho lịch hẹn
  void _showAppointmentMenu(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Consumer<AuthProvider>(builder: (context, auth, _) {
                final items = <Widget>[];
                if (auth.canEditAppointment) {
                  items.add(ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Sửa lịch hẹn'),
                    onTap: () {
                      Navigator.pop(context);
                      // Chuyển sang màn sửa lịch hẹn nếu có
                    },
                  ));
                }
                if (auth.canCancelAppointment) {
                  items.add(ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Xóa lịch hẹn'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteAppointment(appointment);
                    },
                  ));
                }
                return Column(children: items);
              }),
            ],
          ),
        );
      },
    );
  }

  // Hiển thị chi tiết lịch hẹn
  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        return AlertDialog(
          title: const Text('Chi tiết lịch hẹn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.person, 'Bệnh nhân', appointment.patientInfo?.fullName ?? 'N/A'),
              _buildInfoRow(Icons.phone, 'SĐT', appointment.patientInfo?.phone ?? ''),
              _buildInfoRow(Icons.calendar_today, 'Ngày', dateFormat.format(appointment.appointmentDate)),
              _buildInfoRow(Icons.access_time, 'Giờ', appointment.appointmentTime),
              if (appointment.doctorName != null)
                _buildInfoRow(Icons.person, 'Bác sĩ', appointment.doctorName!),
              if (appointment.roomNumber != null)
                _buildInfoRow(Icons.meeting_room, 'Phòng', appointment.roomNumber!),
              if (appointment.reason != null)
                _buildInfoRow(Icons.description, 'Lý do', appointment.reason!),
              _buildStatusChip(appointment.status),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
