import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/dashboard/presentation/providers/passenger_home_providers.dart';
import '../../../../features/dashboard/presentation/widgets/passenger_offer_card.dart';

class PassengerOffersScreen extends ConsumerWidget {
  const PassengerOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final offersAsync = ref.watch(dashboardOffersProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'العروض والخصومات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF0B1F3A) : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5A623).withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        size: 40,
                        color: Color(0xFFF5A623),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لا توجد عروض حالياً',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ترقب عروضنا وخصوماتنا الحصرية للرحلات قريباً',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: offers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: double.infinity,
                child: PassengerOfferCard(offer: offers[index]),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF5A623)),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل العروض',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(dashboardOffersProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
