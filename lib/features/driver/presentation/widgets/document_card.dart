import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/driver_status_ui.dart';
import '../utils/driver_tokens.dart';

class DocumentInfoField {
  final String label;
  final String value;

  DocumentInfoField({required this.label, required this.value});
}

class DocumentCard extends StatelessWidget {
  final String title;
  final String type;
  final String status;
  final List<DocumentInfoField> fields;
  final String? lastUpdated;
  final int? daysUntilExpiry;

  const DocumentCard({
    super.key,
    required this.title,
    required this.type,
    required this.status,
    required this.fields,
    this.lastUpdated,
    this.daysUntilExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final normStatus = status.toLowerCase();
    final bool isMissing = normStatus == 'missing' || normStatus == 'غير متوفر';
    final bool isExpired =
        normStatus == 'expired' ||
        (daysUntilExpiry != null && daysUntilExpiry! <= 0);
    final bool isRejected = normStatus == 'rejected';
    final bool isNeedsUpdate =
        normStatus == 'needs_update' || normStatus == 'needs_reupload';

    final bool requiresAction =
        isMissing || isExpired || isRejected || isNeedsUpdate;

    return Card(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        side: BorderSide(
          color: requiresAction
              ? DriverTokens.semanticWarning.withValues(alpha: 0.5)
              : (isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.05)),
          width: requiresAction ? 1.5 : 1.0,
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DriverTokens.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Cairo',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
          ),

          if (fields.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DriverTokens.spaceMd,
                vertical: DriverTokens.spaceSm,
              ),
              child: Column(
                children: fields
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              field.label,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              field.value,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          if (lastUpdated != null && lastUpdated!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: DriverTokens.spaceMd,
                right: DriverTokens.spaceMd,
                bottom: DriverTokens.spaceSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آخر تحديث',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    lastUpdated!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

          // Expiration warning if approaching expiry
          if (!isExpired &&
              daysUntilExpiry != null &&
              daysUntilExpiry! <= 30 &&
              daysUntilExpiry! > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DriverTokens.spaceMd,
                vertical: 6,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DriverTokens.semanticWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                  border: Border.all(
                    color: DriverTokens.semanticWarning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: DriverTokens.semanticWarning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تنبيه: تنتهي صلاحية الوثيقة خلال $daysUntilExpiry يوماً',
                        style: const TextStyle(
                          color: DriverTokens.semanticWarning,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Safe controlled action flow for rejected / expired / needs_update (Part 42)
          if (requiresAction)
            Padding(
              padding: const EdgeInsets.all(DriverTokens.spaceMd),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isRejected
                          ? DriverTokens.semanticError
                          : DriverTokens.semanticWarning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRejected
                            ? 'تم رفض الوثيقة من الإدارة. يرجى مراجعة الدعم.'
                            : isExpired
                            ? 'الوثيقة منتهية الصلاحية وتتطلب التجديد.'
                            : 'مطلوب تحديث الوثيقة بطلب من الإدارة.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.push('/driver-support');
                      },
                      icon: const Icon(Icons.support_agent_rounded, size: 16),
                      label: const Text(
                        'الدعم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: DriverTokens.primaryNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    switch (type) {
      case 'passport':
      case 'identity':
        icon = Icons.badge_rounded;
        break;
      case 'driving_license':
        icon = Icons.drive_eta_rounded;
        break;
      case 'vehicle_registration':
        icon = Icons.description_rounded;
        break;
      case 'insurance':
        icon = Icons.security_rounded;
        break;
      case 'vehicle_info':
        icon = Icons.directions_car_rounded;
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DriverTokens.primaryNavy.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: DriverTokens.primaryNavy, size: 22),
    );
  }

  Widget _buildStatusBadge() {
    final docStatus = DocumentStatusUi.fromStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: docStatus.backgroundColor,
        borderRadius: BorderRadius.circular(DriverTokens.radiusPill),
        border: Border.all(color: docStatus.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(docStatus.icon, size: 13, color: docStatus.color),
          const SizedBox(width: 4),
          Text(
            docStatus.label,
            style: TextStyle(
              color: docStatus.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
