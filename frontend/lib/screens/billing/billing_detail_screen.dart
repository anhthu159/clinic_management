import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

class BillingDetailScreen extends StatefulWidget {
	final String billingId;
	const BillingDetailScreen({super.key, required this.billingId});

	@override
	State<BillingDetailScreen> createState() => _BillingDetailScreenState();
}

class _BillingDetailScreenState extends State<BillingDetailScreen> {
	final ApiService _api = ApiService();
	Map<String, dynamic>? _billing;
	bool _isLoading = true;

	@override
	void initState() {
		super.initState();
		_loadBilling();
	}

	Future<void> _loadBilling() async {
		try {
			final response = await _api.get('${AppConfig.billingEndpoint}/${widget.billingId}');
			if (response['success']) {
				setState(() {
					_billing = response['data'];
					_isLoading = false;
				});
			} else {
				setState(() => _isLoading = false);
			}
		} catch (e) {
			if (mounted) {
				setState(() => _isLoading = false);
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Lỗi tải hóa đơn: $e')),
				);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

		Widget body;
		if (_isLoading) {
			body = const Center(child: CircularProgressIndicator());
		} else if (_billing == null) {
			body = const Center(child: Text('Không tìm thấy hóa đơn'));
		} else {
			body = ListView(
				padding: const EdgeInsets.all(16),
				children: [
					Card(
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										_billing!['patientId']?['fullName'] ?? 'N/A',
										style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
									),
									const SizedBox(height: 8),
									Text(
										_billing!['medicalRecordId']?['visitDate'] != null
												? dateFormat.format(DateTime.parse(_billing!['medicalRecordId']['visitDate']))
												: dateFormat.format(DateTime.parse(_billing!['createdAt'])),
										style: const TextStyle(color: AppTheme.textSecondary),
									),
									const SizedBox(height: 12),
									const Divider(),
									const SizedBox(height: 12),
									const Text('Chi tiết dịch vụ', style: TextStyle(fontWeight: FontWeight.w600)),
									const SizedBox(height: 8),
									if ((_billing!['serviceCharges'] as List?)?.isNotEmpty ?? false)
										...(_billing!['serviceCharges'] as List).map((s) {
											return ListTile(
												title: Text(s['serviceName'] ?? ''),
												trailing: Text(_formatCurrency((s['price'] ?? 0).toDouble())),
											);
										}),
									const SizedBox(height: 8),
									const Text('Đơn thuốc', style: TextStyle(fontWeight: FontWeight.w600)),
									const SizedBox(height: 8),
									if ((_billing!['medicineCharges'] as List?)?.isNotEmpty ?? false)
										...(_billing!['medicineCharges'] as List).map((m) {
											return ListTile(
												title: Text(m['medicineName'] ?? ''),
												subtitle: Text('x${m['quantity'] ?? 1}'),
												trailing: Text(_formatCurrency(((m['price'] ?? 0) * (m['quantity'] ?? 1)).toDouble())),
											);
										}),
									const SizedBox(height: 12),
									const Divider(),
									const SizedBox(height: 12),
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											const Text('Tạm tính'),
											Text(_formatCurrency((_billing!['subtotal'] ?? 0).toDouble())),
										],
									),
									if ((_billing!['discount'] ?? 0) > 0) ...[
										const SizedBox(height: 8),
										Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: [
												const Text('Giảm giá'),
												Text('- ${_formatCurrency((_billing!['discount'] ?? 0).toDouble())}'),
											],
										),
									],
									const SizedBox(height: 8),
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold)),
											Text(_formatCurrency((_billing!['totalAmount'] ?? 0).toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
										],
									),
								],
							),
						),
					),
				],
			);
		}

		return Scaffold(
			appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
			body: body,
		);
	}

	String _formatCurrency(double value) {
		final amount = value.toInt();
		return '${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => '${m[1]},')}đ';
	}

}

