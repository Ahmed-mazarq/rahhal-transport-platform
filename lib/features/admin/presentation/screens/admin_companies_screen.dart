import 'package:flutter/material.dart';

class AdminCompaniesScreen extends StatelessWidget {
  const AdminCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AdminCompanies',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: const Center(
        child: Text(
          'AdminCompanies Placeholder',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
