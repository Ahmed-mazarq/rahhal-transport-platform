import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_support_providers.dart';

class DriverFaqScreen extends ConsumerWidget {
  const DriverFaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqsAsync = ref.watch(driverFaqsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأسئلة الشائعة'), centerTitle: true),
      body: faqsAsync.when(
        data: (faqs) {
          if (faqs.isEmpty) {
            return const Center(
              child: Text('لا توجد أسئلة شائعة متاحة حالياً.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    faq.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      faq.answer,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          if (e is FirebaseException) {
            debugPrint('--- FIRESTORE ERROR in DriverFaqScreen.faqsAsync ---');
            debugPrint('Code: \${e.code}');
            debugPrint('Message: \${e.message}');
            debugPrint(e.stackTrace?.toString() ?? st.toString());
          } else {
            debugPrint('Error loading faqs: \$e\\n\$st');
          }
          return Center(child: Text('حدث خطأ: \$e'));
        },
      ),
    );
  }
}
