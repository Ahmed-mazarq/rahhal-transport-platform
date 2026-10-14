import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../marketing/domain/models/offer.dart';

class PassengerOfferCard extends StatelessWidget {
  final Offer offer;

  const PassengerOfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final discountText =
        offer.discountPercent == offer.discountPercent.roundToDouble()
        ? '${offer.discountPercent.toInt()}%'
        : '${offer.discountPercent}%';

    final expiryFormatted = DateFormat('yyyy/MM/dd').format(offer.expiryDate);

    final cardBg = isDark ? const Color(0xFF141F30) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF0B1F3A).withValues(alpha: 0.06);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0B1F3A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Banner: Discount Badge + Expiry
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      size: 16,
                      color: Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'خصم $discountText',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF5A623),
                      ),
                    ),
                  ],
                ),
                Text(
                  'ينتهي: $expiryFormatted',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Middle Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.maxDiscount > 0) ...[
                  Text(
                    'حد أقصى للخصم: ${offer.maxDiscount.toStringAsFixed(0)} ريال',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Coupon Code Box + Copy Action
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        offer.code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFFF5A623)
                              : const Color(0xFF0B1F3A),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'نسخ رمز الخصم ${offer.code}',
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: offer.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم نسخ رمز العرض: ${offer.code}',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: Color(0xFFF5A623),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'نسخ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF5A623),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
