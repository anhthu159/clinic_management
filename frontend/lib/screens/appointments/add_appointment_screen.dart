import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/patient.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  // Form fields
  Patient? _selectedPatient;
  DateTime _appointmentDate = DateTime.now();
  TimeOfDay _appointmentTime = TimeOfDay.now();
  final _doctorNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  List<Patient> _patients = [];
  bool _loadingPatients = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _roomNumberController.dispose();
    _serviceTypeController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _loadingPatients = true);
    try {
      final response = await _api.get(AppConfig.patientsEndpoint);
      if (response['success']) {
        setState(() {
          _patients = (response['data'] as List)
              .map((json) => Patient.fromJson(json))
              .toList();
          _loadingPatients = false;
        });
      }
    } catch (e) {
      setState(() => _loadingPatients = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _appointmentDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _appointmentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _appointmentTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bệnh nhân')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeStr = '${_appointmentTime.hour.toString().padLeft(2, '0')}:${_appointmentTime.minute.toString().padLeft(2, '0')}';
      
      final data = {
        'patientId': _selectedPatient!.id,
        'appointmentDate': _appointmentDate.toIso8601String(),
        'appointmentTime': timeStr,
        if (_doctorNameController.text.isNotEmpty)
          'doctorName': _doctorNameController.text.trim(),
        if (_roomNumberController.text.isNotEmpty)
          'roomNumber': _roomNumberController.text.trim(),
        if (_serviceTypeController.text.isNotEmpty)
          'serviceType': _serviceTypeController.text.trim(),
        if (_reasonController.text.isNotEmpty)
          'reason': _reasonController.text.trim(),
        if (_notesController.text.isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      final response = await _api.post(AppConfig.appointmentsEndpoint, data);

      if (mounted) {
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt lịch hẹn thành công'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch hẹn'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Selection
            _buildSectionTitle('Thông tin bệnh nhân'),
            const SizedBox(height: 16),

            _loadingPatients
                ? const Center(child: CircularProgressIndicator())
                : InkWell(
                    onTap: () => _showPatientPicker(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Chọn bệnh nhân *',
                        prefixIcon: Icon(Icons.person_search),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _selectedPatient?.fullName ?? 'Chọn bệnh nhân',
                        style: TextStyle(
                          color: _selectedPatient != null 
                              ? AppTheme.black 
                              : AppTheme.grey,
                        ),
                      ),
                    ),
                  ),

            if (_selectedPatient != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      _selectedPatient!.phone,
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedPatient!.patientType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionTitle('Thời gian'),
            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày hẹn *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        dateFormat.format(_appointmentDate),
                        style: const TextStyle(color: AppTheme.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Giờ hẹn *',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _appointmentTime.format(context),
                        style: const TextStyle(color: AppTheme.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Chi tiết khám'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Bác sĩ',
                prefixIcon: Icon(Icons.person),
                hintText: 'Tên bác sĩ khám',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _roomNumberController,
              decoration: const InputDecoration(
                labelText: 'Phòng khám',
                prefixIcon: Icon(Icons.meeting_room),
                hintText: 'Số phòng',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _serviceTypeController,
              decoration: const InputDecoration(
                labelText: 'Loại dịch vụ',
                prefixIcon: Icon(Icons.medical_services),
                hintText: 'VD: Khám tổng quát, Siêu âm...',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do khám',
                prefixIcon: Icon(Icons.description),
                hintText: 'Triệu chứng hoặc lý do đến khám',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.note),
                hintText: 'Ghi chú thêm (nếu có)',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAppointment,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Đặt lịch hẹn',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
      ],
    );
  }

  void _showPatientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Chọn bệnh nhân',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final patient = _patients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen,
                          child: Text(
                            patient.fullName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(patient.fullName),
                        subtitle: Text(patient.phone),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            patient.patientType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedPatient = patient);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}