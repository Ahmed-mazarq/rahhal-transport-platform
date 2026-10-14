import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../../../../core/providers/system_config_provider.dart';
import 'package:intl/intl.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    final messageAr =
        settingsAsync.value?.maintenanceMessageAr ??
        'نظام رحّال تحت الصيانة حالياً';
    final messageEn =
        settingsAsync.value?.maintenanceMessageEn ??
        'Rahhal system is currently under maintenance';

    final maintenanceUntil = settingsAsync.value?.maintenanceUntil;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 100,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 32),
              const Text(
                'رحّال تحت الصيانة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F3A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                messageAr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              if (messageEn.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  messageEn,
                  textAlign: TextAlign.center,
                  textDirection: ui.TextDirection.ltr,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              if (maintenanceUntil != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الوقت المتوقع لانتهاء الصيانة:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'yyyy-MM-dd hh:mm a',
                        ).format(maintenanceUntil),
                        textDirection: ui.TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(appSettingsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F3A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
