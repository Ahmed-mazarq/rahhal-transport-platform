import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String
  type; // booking, trip, payment, support, parcel, promotion, system
  final DateTime timestamp;
  final bool isRead;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData icon;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'booking':
        icon = Icons.confirmation_number_rounded;
        iconColor = const Color(0xFF0B1F3A);
        break;
      case 'trip':
        icon = Icons.route_rounded;
        iconColor = Colors.teal;
        break;
      case 'payment':
        icon = Icons.payments_rounded;
        iconColor = const Color(0xFFF5A623);
        break;
      case 'support':
        icon = Icons.support_agent_rounded;
        iconColor = Colors.blue;
        break;
      case 'parcel':
        icon = Icons.inventory_2_rounded;
        iconColor = Colors.deepOrange;
        break;
      case 'promotion':
      case 'offer':
        icon = Icons.local_offer_rounded;
        iconColor = Colors.purple;
        break;
      case 'system':
      case 'general':
      default:
        icon = Icons.notifications_rounded;
        iconColor = Colors.blueGrey;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
              : (isDark ? const Color(0xFF262D38) : const Color(0xFFF0F5FD)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.grey[850]! : Colors.grey[200]!)
                : (isDark ? const Color(0xFF35445A) : const Color(0xFFD6E4F8)),
          ),
          boxShadow: isRead
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5A623),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inHours < 1) {
      return 'منذ ${diff.inMinutes} د';
    } else if (diff.inDays < 1) {
      return 'منذ ${diff.inHours} س';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} ي';
    } else {
      return DateFormat('MM/dd', 'ar').format(dt);
    }
  }
}
