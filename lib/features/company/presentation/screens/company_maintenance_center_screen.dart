import 'package:flutter/material.dart';

class CompanyMaintenanceCenterScreen extends StatelessWidget {
  const CompanyMaintenanceCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'مركز صيانة الأسطول',
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
              tabs: [
                Tab(text: 'التنبيهات والمواعيد'),
                Tab(text: 'سجل الصيانة'),
              ],
            ),
          ),
          body: TabBarView(children: [_buildAlertsTab(), _buildHistoryTab()]),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.build),
            label: const Text(
              'تسجيل صيانة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFF0B1F3A),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMaintenanceCard(
          'تغيير زيت وفلاتر',
          'مرسيدس باص (KSA 1234)',
          'بعد 500 كم',
          Colors.orange,
        ),
        _buildMaintenanceCard(
          'فحص فرامل',
          'تويوتا هايس (KSA 9988)',
          'متأخر (تجاوز الموعد)',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMaintenanceCard(
          'تغيير إطارات',
          'هيونداي (KSA 5544)',
          'تم في 12 أكتوبر 2023',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMaintenanceCard(
    String task,
    String vehicle,
    String status,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.build, color: color),
        ),
        title: Text(
          task,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          vehicle,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
