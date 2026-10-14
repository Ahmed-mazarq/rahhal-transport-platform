import 'package:flutter/material.dart';

class AdminPassengersScreen extends StatelessWidget {
  const AdminPassengersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AdminPassengers',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: const Center(
        child: Text(
          'AdminPassengers Placeholder',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
