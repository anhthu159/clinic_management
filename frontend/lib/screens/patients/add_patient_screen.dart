import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _idCardController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _dateOfBirth;
  String _gender = 'Nam';
  String _patientType = 'Thường';

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color bg = Color(0xFFF6F8F7);

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idCardController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày sinh')));
      return;
    }

    setState(() => _isLoading = true);
    // Capture messenger/navigator before async gaps to avoid use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final data = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'gender': _gender,
        'patientType': _patientType,
        'address': _addressController.text.trim(),
        'idCard': _idCardController.text.trim(),
        'email': _emailController.text.trim(),
      };
      final response = await _api.post(AppConfig.patientsEndpoint, data);
      if (!mounted) return;
      if (response['success']) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Thêm bệnh nhân thành công'),
              backgroundColor: Colors.green),
        );
  navigator.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header gradient giống Dashboard
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryGreen, accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 26),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thêm bệnh nhân mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nhập thông tin cá nhân và loại bệnh nhân',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 242),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 15),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInput(_fullNameController, 'Họ và tên *', Icons.person,
                        validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập họ tên' : null),
                    _buildInput(_phoneController, 'Số điện thoại *', Icons.phone,
                        type: TextInputType.phone,
                        validator: (v) => RegExp(r'^[0-9]{10}$')
                                .hasMatch(v ?? '')
                            ? null
                            : 'Số điện thoại không hợp lệ'),
                    _buildDatePicker(dateFormat),
                    _buildDropdown('Giới tính', _gender, ['Nam', 'Nữ', 'Khác'],
                        (v) => setState(() => _gender = v!)),
                    _buildInput(_idCardController, 'CMND/CCCD', Icons.credit_card,
                        type: TextInputType.number),
                    _buildInput(_emailController, 'Email', Icons.email,
                        type: TextInputType.emailAddress),
                    _buildInput(_addressController, 'Địa chỉ', Icons.location_on,
                        lines: 2),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Loại bệnh nhân'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildPatientTypeChip('Thường', Colors.grey),
                        _buildPatientTypeChip('BHYT', accentGreen),
                        _buildPatientTypeChip('VIP', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        onPressed: _isLoading ? null : _savePatient,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : const Text('Lưu thông tin',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon,
      {TextInputType? type, int lines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: lines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePicker(DateFormat dateFormat) {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày sinh *',
          prefixIcon: const Icon(Icons.cake, color: primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _dateOfBirth != null
              ? dateFormat.format(_dateOfBirth!)
              : 'Chọn ngày sinh',
          style: TextStyle(
              color: _dateOfBirth != null ? Colors.black : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, String currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.wc, color: primaryGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        initialValue: currentValue,
        onChanged: onChanged,
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: primaryGreen)),
      );

  Widget _buildPatientTypeChip(String type, Color color) {
    final isSelected = _patientType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (_) => setState(() => _patientType = type),
      selectedColor: color,
  backgroundColor: color.withValues(alpha: 26),
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
