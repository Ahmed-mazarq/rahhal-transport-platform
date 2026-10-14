import 'package:flutter/material.dart';
import 'company_vehicles_tab.dart';
import 'company_drivers_tab.dart';

class CompanyFleetScreen extends StatelessWidget {
  const CompanyFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'إدارة الأسطول',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: const TabBar(
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              indicatorColor: Color(0xFF0B1F3A),
              tabs: [
                Tab(text: 'المركبات', icon: Icon(Icons.directions_car)),
                Tab(text: 'السائقين', icon: Icon(Icons.people)),
                Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              CompanyVehiclesTab(),
              CompanyDriversTab(),
              Center(
                child: Text(
                  'نظرة عامة على الأسطول (قريباً)',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
