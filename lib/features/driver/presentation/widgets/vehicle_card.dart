import 'package:flutter/material.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../utils/driver_status_ui.dart';
import '../utils/driver_tokens.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;
  final bool isPrimary;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final bool hasInsuranceWarning =
        vehicle.insuranceExpiry != null &&
        vehicle.insuranceExpiry!.difference(now).inDays < 30;
    final bool hasRegistrationWarning =
        vehicle.registrationExpiry != null &&
        vehicle.registrationExpiry!.difference(now).inDays < 30;

    final effectivePrimary = isPrimary || vehicle.isDefault;

    return Card(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade100,
                  child: vehicle.photoUrl.isNotEmpty
                      ? Image.network(
                          vehicle.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.directions_car,
                            size: 72,
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade400,
                          ),
                        )
                      : Icon(
                          Icons.directions_car,
                          size: 72,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                ),
                // Primary badge at top right
                if (effectivePrimary)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: DriverTokens.primaryNavy,
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusPill,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: DriverTokens.accentGold,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'المركبة الأساسية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Status badge at top left
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildStatusBadge(context),
                ),
              ],
            ),
            if (vehicle.additionalPhotos.isNotEmpty) ...[
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.grey.shade50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: vehicle.additionalPhotos.length + 1,
                  itemBuilder: (context, idx) {
                    final bool isMain = idx == 0;
                    final String url = isMain
                        ? vehicle.photoUrl
                        : vehicle.additionalPhotos[idx - 1];
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusSmall,
                        ),
                        border: Border.all(
                          color: isMain
                              ? DriverTokens.accentGold
                              : (isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                          width: isMain ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image, size: 18),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.all(DriverTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.make} ${vehicle.model} ${vehicle.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            fontFamily: 'Cairo',
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehicle.plateNumber,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DriverTokens.spaceSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip(
                        context,
                        Icons.event_seat_rounded,
                        '${vehicle.seatsCount} مقاعد',
                      ),
                      _buildChip(context, Icons.category_rounded, vehicle.type),
                      _buildChip(
                        context,
                        Icons.local_gas_station_rounded,
                        vehicle.fuelType,
                      ),
                    ],
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),
                  if (!effectivePrimary)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: DriverTokens.spaceSm,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onSetPrimary,
                          icon: const Icon(
                            Icons.star_outline_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'تعيين كمركبة أساسية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DriverTokens.accentGold,
                            side: const BorderSide(
                              color: DriverTokens.accentGold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DriverTokens.radiusSmall,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        context,
                        'الرحلات',
                        vehicle.tripCount.toString(),
                      ),
                      _buildStatColumn(
                        context,
                        'التقييم',
                        vehicle.tripCount > 0
                            ? '★ ${vehicle.rating.toStringAsFixed(1)}'
                            : '—',
                      ),
                      _buildStatColumn(
                        context,
                        'آخر رحلة',
                        vehicle.lastTripDate != null
                            ? '${vehicle.lastTripDate!.day}/${vehicle.lastTripDate!.month}'
                            : 'لا يوجد',
                      ),
                    ],
                  ),
                  if (hasInsuranceWarning || hasRegistrationWarning) ...[
                    const SizedBox(height: DriverTokens.spaceSm),
                    if (hasInsuranceWarning)
                      _buildWarningRow(
                        'تأمين المركبة شارف على الانتهاء أو انتهى',
                      ),
                    if (hasRegistrationWarning)
                      _buildWarningRow(
                        'استمارة المركبة شارفت على الانتهاء أو انتهت',
                      ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'تعديل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: DriverTokens.semanticError,
                        ),
                        label: const Text(
                          'حذف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: DriverTokens.semanticError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String val) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildWarningRow(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: DriverTokens.semanticWarning,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: DriverTokens.semanticWarning,
                fontSize: 11,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final badge = VehicleStatusUi.fromStatus(vehicle.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badge.backgroundColor,
        borderRadius: BorderRadius.circular(DriverTokens.radiusPill),
        border: Border.all(color: badge.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, color: badge.textColor, size: 13),
          const SizedBox(width: 4),
          Text(
            badge.label,
            style: TextStyle(
              color: badge.textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
