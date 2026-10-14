import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/support_providers.dart';
import '../../../driver_support/presentation/providers/driver_support_providers.dart';

class ContactInfoScreen extends ConsumerWidget {
  final String userType;
  const ContactInfoScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = userType == 'driver'
        ? ref.watch(driverContactInfoProvider)
        : ref.watch(contactInfoProvider(userType));

    return Scaffold(
      appBar: AppBar(title: const Text('معلومات التواصل'), centerTitle: true),
      body: contactAsync.when(
        data: (contact) {
          if (contact == null) {
            return const Center(
              child: Text('معلومات التواصل غير متوفرة حالياً'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(
                    Icons.support_agent,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نحن هنا لمساعدتك',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'تواصل معنا عبر القنوات التالية وسنكون سعداء بخدمتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 32),

                if (contact['phone1'] != null &&
                    contact['phone1'].toString().isNotEmpty)
                  _buildContactCard(
                    icon: Icons.phone,
                    title: 'الرقم الموحد',
                    value: contact['phone1'].toString(),
                    onTap: () {},
                  ),

                if (contact['whatsapp'] != null &&
                    contact['whatsapp'].toString().isNotEmpty)
                  _buildContactCard(
                    icon: Icons.message,
                    title: 'واتساب',
                    value: contact['whatsapp'].toString(),
                    onTap: () {},
                    iconColor: Colors.green,
                  ),

                if (contact['email'] != null &&
                    contact['email'].toString().isNotEmpty)
                  _buildContactCard(
                    icon: Icons.email,
                    title: 'البريد الإلكتروني',
                    value: contact['email'].toString(),
                    onTap: () {},
                  ),

                if (contact['workingHours'] != null &&
                    contact['workingHours'].toString().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ساعات العمل',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                contact['workingHours'].toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (contact['notes'] != null &&
                    contact['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ملاحظات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                contact['notes'].toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('حدث خطأ: $err')),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? AppTheme.primaryColor).withValues(
            alpha: 0.1,
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
