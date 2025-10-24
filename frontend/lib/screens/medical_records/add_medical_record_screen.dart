import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/patient.dart';
import '../../models/service.dart';
import '../../models/medicine.dart';
import '../../models/medical_record.dart';

class AddMedicalRecordScreen extends StatefulWidget {
  final String? patientId;
  
  const AddMedicalRecordScreen({super.key, this.patientId});

  @override
  State<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  // Form Controllers
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  // Data
  Patient? _selectedPatient;
  DateTime _visitDate = DateTime.now();
  List<Patient> _patients = [];
  List<Service> _availableServices = [];
  List<Medicine> _availableMedicines = [];
  
  List<ServiceItem> _selectedServices = [];
  List<PrescriptionItem> _selectedPrescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _doctorNameController.dispose();
    _roomNumberController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load patients
      final patientsResponse = await _api.get(AppConfig.patientsEndpoint);
      if (patientsResponse['success']) {
        _patients = (patientsResponse['data'] as List)
            .map((json) => Patient.fromJson(json))
            .toList();
        
        if (widget.patientId != null) {
          _selectedPatient = _patients.firstWhere(
            (p) => p.id == widget.patientId,
            orElse: () => _patients.first,
          );
        }
      }

      // Load services
      final servicesResponse = await _api.get(AppConfig.servicesEndpoint);
      if (servicesResponse['success']) {
        _availableServices = (servicesResponse['data'] as List)
            .map((json) => Service.fromJson(json))
            .where((s) => s.isActive)
            .toList();
      }

      // Load medicines
      final medicinesResponse = await _api.get(AppConfig.medicinesEndpoint);
      if (medicinesResponse['success']) {
        _availableMedicines = (medicinesResponse['data'] as List)
            .map((json) => Medicine.fromJson(json))
            .toList();
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      setState(() => _visitDate = picked);
    }
  }

  double get _subtotal {
    double serviceTotal = _selectedServices.fold(0, (sum, s) => sum + s.price);
    double medicineTotal = _selectedPrescriptions.fold(
        0, (sum, p) => sum + (p.price * p.quantity));
    return serviceTotal + medicineTotal;
  }

  double get _totalAmount {
    double discount = double.tryParse(_discountController.text) ?? 0;
    return _subtotal - discount;
  }

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bệnh nhân')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'patientId': _selectedPatient!.id,
        'visitDate': _visitDate.toIso8601String(),
        'symptoms': _symptomsController.text.trim(),
        if (_diagnosisController.text.isNotEmpty)
          'diagnosis': _diagnosisController.text.trim(),
        if (_doctorNameController.text.isNotEmpty)
          'doctorName': _doctorNameController.text.trim(),
        if (_roomNumberController.text.isNotEmpty)
          'roomNumber': _roomNumberController.text.trim(),
        'services': _selectedServices.map((s) => s.toJson()).toList(),
        'prescriptions': _selectedPrescriptions.map((p) => p.toJson()).toList(),
        'discount': double.tryParse(_discountController.text) ?? 0,
        if (_notesController.text.isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      final response = await _api.post(AppConfig.medicalRecordsEndpoint, data);

      if (mounted) {
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo hồ sơ thành công'),
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
        title: const Text('Tạo hồ sơ khám bệnh'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Selection
            _buildSectionTitle('Thông tin bệnh nhân'),
            const SizedBox(height: 16),

            InkWell(
              onTap: widget.patientId == null ? _showPatientPicker : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Chọn bệnh nhân *',
                  prefixIcon: const Icon(Icons.person_search),
                  suffixIcon: widget.patientId == null 
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                  enabled: widget.patientId == null,
                ),
                child: Text(
                  _selectedPatient?.fullName ?? 'Chọn bệnh nhân',
                  style: TextStyle(
                    color: _selectedPatient != null ? AppTheme.black : AppTheme.grey,
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
                  border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
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
                    Text(
                      '${_selectedPatient!.age} tuổi',
                      style: const TextStyle(
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionTitle('Thông tin khám'),
            const SizedBox(height: 16),

            // Visit Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày khám *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  dateFormat.format(_visitDate),
                  style: const TextStyle(color: AppTheme.black),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _symptomsController,
              decoration: const InputDecoration(
                labelText: 'Triệu chứng *',
                prefixIcon: Icon(Icons.sick),
                hintText: 'Mô tả triệu chứng của bệnh nhân',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập triệu chứng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Chẩn đoán',
                prefixIcon: Icon(Icons.medical_information),
                hintText: 'Kết quả chẩn đoán',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _doctorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bác sĩ',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _roomNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phòng',
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Dịch vụ khám'),
            const SizedBox(height: 8),
            _buildServicesList(),
            
            ElevatedButton.icon(
              onPressed: _showAddServiceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm dịch vụ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Đơn thuốc'),
            const SizedBox(height: 8),
            _buildPrescriptionsList(),
            
            ElevatedButton.icon(
              onPressed: _showAddMedicineDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue,
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Chi phí'),
            const SizedBox(height: 16),

            // Cost Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.cardGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.cardShadow,
              ),
              child: Column(
                children: [
                  _buildCostRow('Dịch vụ', _selectedServices.fold(
                      0.0, (sum, s) => sum + s.price)),
                  const SizedBox(height: 8),
                  _buildCostRow('Thuốc', _selectedPrescriptions.fold(
                      0.0, (sum, p) => sum + (p.price * p.quantity))),
                  const Divider(height: 24),
                  _buildCostRow('Tạm tính', _subtotal, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Giảm giá',
                prefixIcon: Icon(Icons.discount),
                suffixText: 'đ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TỔNG CỘNG',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryBlue,
                    ),
                  ),
                  Text(
                    _formatCurrency(_totalAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
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
                onPressed: _isLoading ? null : _saveMedicalRecord,
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
                        'Lưu hồ sơ',
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

  Widget _buildServicesList() {
    if (_selectedServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Chưa có dịch vụ nào',
            style: TextStyle(color: AppTheme.grey),
          ),
        ),
      );
    }

    return Column(
      children: _selectedServices.map((service) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.medical_services, color: Colors.white, size: 20),
            ),
            title: Text(service.serviceName),
            subtitle: Text(_formatCurrency(service.price)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: () {
                setState(() {
                  _selectedServices.remove(service);
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrescriptionsList() {
    if (_selectedPrescriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Chưa có thuốc nào',
            style: TextStyle(color: AppTheme.grey),
          ),
        ),
      );
    }

    return Column(
      children: _selectedPrescriptions.map((prescription) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.secondaryBlue,
              child: Icon(Icons.medication, color: Colors.white, size: 20),
            ),
            title: Text(prescription.medicineName),
            subtitle: Text(
              '${prescription.quantity} ${prescription.unit ?? 'viên'} x ${_formatCurrency(prescription.price)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatCurrency(prescription.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: () {
                    setState(() {
                      _selectedPrescriptions.remove(prescription);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.darkGrey,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppTheme.primaryGreen : AppTheme.black,
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        trailing: Text('${patient.age} tuổi'),
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

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn dịch vụ'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableServices.length,
              itemBuilder: (context, index) {
                final service = _availableServices[index];
                final isSelected = _selectedServices.any(
                  (s) => s.serviceName == service.serviceName,
                );
                
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppTheme.success : AppTheme.grey,
                  ),
                  title: Text(service.serviceName),
                  subtitle: Text(_formatCurrency(service.price)),
                  enabled: !isSelected,
                  onTap: isSelected ? null : () {
                    setState(() {
                      _selectedServices.add(ServiceItem(
                        serviceId: service.id,
                        serviceName: service.serviceName,
                        price: service.price,
                      ));
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
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

  void _showAddMedicineDialog() {
    Medicine? selectedMedicine;
    final quantityController = TextEditingController(text: '1');
    final dosageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm thuốc'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Medicine>(
                      value: selectedMedicine,
                      decoration: const InputDecoration(
                        labelText: 'Chọn thuốc',
                        prefixIcon: Icon(Icons.medication),
                      ),
                      items: _availableMedicines.map((medicine) {
                        return DropdownMenuItem(
                          value: medicine,
                          child: Text(medicine.medicineName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedMedicine = value);
                      },
                    ),
                    if (selectedMedicine != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Giá: ${_formatCurrency(selectedMedicine!.price)}/${selectedMedicine!.unit}',
                        style: const TextStyle(color: AppTheme.grey),
                      ),
                      Text(
                        'Tồn kho: ${selectedMedicine!.stockQuantity}',
                        style: TextStyle(
                          color: selectedMedicine!.isLowStock 
                              ? AppTheme.warning 
                              : AppTheme.success,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Liều dùng',
                        prefixIcon: Icon(Icons.schedule),
                        hintText: 'VD: 2 viên/lần, 3 lần/ngày',
                      ),
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
                  onPressed: () {
                    if (selectedMedicine != null) {
                      final quantity = int.tryParse(quantityController.text) ?? 1;
                      
                      this.setState(() {
                        _selectedPrescriptions.add(PrescriptionItem(
                          medicineId: selectedMedicine!.id,
                          medicineName: selectedMedicine!.medicineName,
                          quantity: quantity,
                          unit: selectedMedicine!.unit,
                          price: selectedMedicine!.price,
                          dosage: dosageController.text.isNotEmpty 
                              ? dosageController.text 
                              : null,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(double value) {
    final amount = value.toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
}