import 'package:flutter/material.dart';

class CompanyDocumentAlertsScreen extends StatelessWidget {
  const CompanyDocumentAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تنبيهات الوثائق والتراخيص',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'تنبيهات وثائق السائقين والمركبات والشركة',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildAlertCard(
              'رخصة قيادة السائق',
              'محمد عبدالله',
              'تنتهي غداً',
              Colors.red,
              Icons.badge,
            ),
            _buildAlertCard(
              'تأمين المركبة',
              'KSA 1234',
              'ينتهي بعد 7 أيام',
              Colors.orange,
              Icons.security,
            ),
            _buildAlertCard(
              'السجل التجاري للشركة',
              'شركة نقل رحال',
              'ساري (يتبقى 8 أشهر)',
              Colors.green,
              Icons.domain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    String type,
    String entity,
    String expiry,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          type,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          entity,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            expiry,
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
