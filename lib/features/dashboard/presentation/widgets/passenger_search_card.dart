import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../trips/presentation/providers/passenger_search_provider.dart';

import '../providers/passenger_navigation_provider.dart';

class PassengerSearchCard extends ConsumerWidget {
  const PassengerSearchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchFilter = ref.watch(passengerSearchFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final depName =
        searchFilter.departureProvince?.nameAr ??
        searchFilter.departureCountry?.nameAr ??
        '';
    final arrName =
        searchFilter.arrivalProvince?.nameAr ??
        searchFilter.arrivalCountry?.nameAr ??
        '';

    final bool hasRoute = depName.isNotEmpty || arrName.isNotEmpty;
    final int count = searchFilter.passengerCount;

    String passengerLabel;
    if (count == 1) {
      passengerLabel = 'مسافر واحد';
    } else if (count == 2) {
      passengerLabel = 'مسافران';
    } else if (count <= 10) {
      passengerLabel = '$count مسافرين';
    } else {
      passengerLabel = '$count مسافر';
    }

    final cardBg = isDark ? const Color(0xFF141F30) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF0B1F3A).withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Semantics(
        button: true,
        label: hasRoute
            ? 'البحث عن رحلة من $depName إلى $arrName، $passengerLabel'
            : 'البحث عن رحلة جديدة',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(passengerTabIndexProvider.notifier).state = 1;
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFF0B1F3A).withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Gold compact icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5A623), Color(0xFFE09015)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF5A623,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle / Selected Route
                  Expanded(
                    child: hasRoute
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      depName.isNotEmpty ? depName : 'الانطلاق',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0B1F3A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Color(0xFFF5A623),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      arrName.isNotEmpty ? arrName : 'الوجهة',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0B1F3A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                passengerLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'إلى أين تريد السفر؟',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0B1F3A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'اختر نقطة الانطلاق والوجهة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  // CTA button or arrow
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF0B1F3A,
                      ).withValues(alpha: isDark ? 0.4 : 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ابحث',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFF5A623)
                                : const Color(0xFF0B1F3A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: isDark
                              ? const Color(0xFFF5A623)
                              : const Color(0xFF0B1F3A),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
