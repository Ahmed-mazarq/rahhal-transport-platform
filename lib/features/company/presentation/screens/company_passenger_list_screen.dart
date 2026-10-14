import 'package:flutter/material.dart';

class CompanyPassengerListScreen extends StatelessWidget {
  const CompanyPassengerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'قائمة الركاب - TRP-1002',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {},
            ), // Export
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4, // Mock count
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF0B1F3A,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF0B1F3A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: const Text(
                  'سالم عبدالله',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'مقعد: 12 | الدفع: مؤكد',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceBtn('حاضر', Icons.check, Colors.green),
                        _buildAttendanceBtn('غائب', Icons.close, Colors.red),
                        _buildAttendanceBtn(
                          'متأخر',
                          Icons.timer,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceBtn(String label, IconData icon, Color color) {
    return Column(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(icon, color: color),
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
