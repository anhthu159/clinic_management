import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/appointment.dart';

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
  DateTime _selectedDate = DateTime.now();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/appointments/add');
          if (result == true) {
            _loadAppointments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Đặt lịch hẹn'),
      ),
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
                      color: AppTheme.accentGreen.withOpacity(0.2),
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
            ...appointments.map((apt) => _buildAppointmentCard(apt)).toList(),
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
                    TextButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                          appointment.id!, 'Đã khám'),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Đã khám'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                          appointment.id!, 'Hủy'),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Hủy'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showAppointmentMenu(appointment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== Các hàm phụ ==========

  Widget _buildInfoRow(IconData icon, String label, String value) { ... }

  Widget _buildStatusChip(String status) { ... }

  Widget _buildEmptyState(String message) { ... }

  void _showAppointmentDetails(Appointment appointment) { ... }

  void _showAppointmentMenu(Appointment appointment) { ... }

  void _confirmDelete(Appointment appointment) { ... }
}
