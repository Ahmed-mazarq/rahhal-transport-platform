import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../trips/domain/models/trip.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';

class DriverTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onCancel;

  const DriverTripCard({
    super.key,
    required this.trip,
    required this.onViewDetails,
    this.onEdit,
    this.onDuplicate,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusUi = DriverTripStatusUi.fromStatus(trip.status);

    final int bookedSeats = trip.totalSeats - trip.remainingSeats;
    final double occupancy = trip.totalSeats > 0
        ? (bookedSeats / trip.totalSeats).clamp(0.0, 1.0)
        : 0.0;

    final formattedDate = DateFormat(
      'yyyy/MM/dd - hh:mm a',
      'ar',
    ).format(trip.departureTime);

    final currencyLabel = trip.currency.isNotEmpty
        ? trip.currency.toUpperCase()
        : 'SAR';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: DriverTokens.borderCard,
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      color: isDark ? DriverTokens.cardDark : Colors.white,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: DriverTokens.borderCard,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Route & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: DriverTokens.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            trip.departureCity,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : DriverTokens.primaryNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            trip.arrivalCity,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : DriverTokens.primaryNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusUi.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusUi.icon,
                          size: 14,
                          color: statusUi.foregroundColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusUi.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusUi.foregroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date, Vehicle & Parcel indicator
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  if (trip.parcelPrice != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DriverTokens.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: DriverTokens.warning,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'يقبل الطرود',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: DriverTokens.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Vehicle Plate & Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 15,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${trip.vehicleBrand} ${trip.vehicleModel} (${trip.vehiclePlate})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${trip.price.toStringAsFixed(0)} $currencyLabel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DriverTokens.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Occupancy Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المقاعد المحجوزة: $bookedSeats / ${trip.totalSeats}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${(occupancy * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: occupancy,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                    color: occupancy >= 1.0
                        ? DriverTokens.error
                        : (occupancy > 0.6
                              ? DriverTokens.warning
                              : DriverTokens.success),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Contextual Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null &&
                      (trip.status == 'draft' ||
                          trip.status == 'published' ||
                          trip.status == 'open_for_booking')) ...[
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: DriverTokens.error,
                      ),
                      label: const Text(
                        'إلغاء الرحلة',
                        style: TextStyle(
                          fontSize: 12,
                          color: DriverTokens.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onDuplicate != null) ...[
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'تكرار الرحلة',
                      onPressed: onDuplicate,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (onEdit != null &&
                      (trip.status == 'draft' ||
                          trip.status == 'published')) ...[
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text(
                        'تعديل',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: trip.status == 'running'
                          ? DriverTokens.accentGold
                          : DriverTokens.primaryNavy,
                      foregroundColor: trip.status == 'running'
                          ? Colors.black87
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      trip.status == 'running' ? 'متابعة الرحلة' : 'التفاصيل',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
