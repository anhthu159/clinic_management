import 'package:flutter/material.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách dịch vụ')),
      body: const Center(
        child: Text('Chưa có dữ liệu dịch vụ.'),
      ),
    );
  }
}
