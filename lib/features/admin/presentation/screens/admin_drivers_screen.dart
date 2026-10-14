import 'package:flutter/material.dart';

class AdminDriversScreen extends StatelessWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AdminDrivers',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: const Center(
        child: Text(
          'AdminDrivers Placeholder',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
