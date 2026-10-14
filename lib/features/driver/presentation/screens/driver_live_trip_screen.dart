import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../trips/domain/models/trip.dart';
import '../../../../core/providers/repository_providers.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';

class DriverLiveTripScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const DriverLiveTripScreen({super.key, required this.trip});

  @override
  ConsumerState<DriverLiveTripScreen> createState() =>
      _DriverLiveTripScreenState();
}

class _DriverLiveTripScreenState extends ConsumerState<DriverLiveTripScreen> {
  bool _isLoading = false;

  Future<void> _finishTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد إنهاء الرحلة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من اكتمال الرحلة من ${widget.trip.departureCity} إلى ${widget.trip.arrivalCity}؟ سيتم تحديث حالة الرحلة لجميع الركاب والإدارة إلى مكتملة.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTokens.semanticSuccess,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'نعم، تم إنهاء الرحلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .updateTripStatus(widget.trip.id, 'completed');

      if (mounted) {
        context.go('/driver-dashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنهاء الرحلة بنجاح واكتمال وصول الركاب',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر إنهاء الرحلة، يرجى المحاولة مرة أخرى',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trip = widget.trip;
    final statusUi = DriverTripStatusUi.fromStatus(trip.status);

    final bookedSeatsCount = (trip.totalSeats - trip.remainingSeats).clamp(
      0,
      trip.totalSeats,
    );
    final departureDateStr = DateFormat(
      'yyyy/MM/dd – hh:mm a',
    ).format(trip.departureTime);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101928)
            : DriverTokens.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101928) : Colors.white,
          elevation: 0,
          title: Text(
            'متابعة الرحلة #${trip.id.length > 6 ? trip.id.substring(0, 6) : trip.id}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusUi.backgroundColor,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusPill),
                  border: Border.all(
                    color: statusUi.foregroundColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusUi.icon,
                      color: statusUi.foregroundColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusUi.label,
                      style: TextStyle(
                        color: statusUi.foregroundColor,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(DriverTokens.spaceMd),
          children: [
            // Route Banner Card
            Container(
              padding: const EdgeInsets.all(DriverTokens.spaceMd),
              decoration: BoxDecoration(
                color: DriverTokens.primaryNavy,
                borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              trip.departureCity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: DriverTokens.accentGold,
                                size: 20,
                              ),
                            ),
                            Text(
                              trip.arrivalCity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        departureDateStr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      if (trip.vehiclePlate.isNotEmpty) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trip.vehiclePlate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: DriverTokens.spaceMd),

            // Real telemetry / GPS Notice Banner (Part 34)
            Container(
              padding: const EdgeInsets.all(DriverTokens.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DriverTokens.semanticInfo.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_disabled_rounded,
                      color: DriverTokens.semanticInfo,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التتبع الحي عبر الخريطة غير متوفر حالياً',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تعتمد المتابعة على محطات المسار وتأكيد حضور الركاب بالمركبة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DriverTokens.spaceMd),

            // Real Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    Icons.people_alt_rounded,
                    DriverTokens.semanticInfo,
                    'المقاعد المحجوزة',
                    '$bookedSeatsCount / ${trip.totalSeats}',
                  ),
                ),
                const SizedBox(width: DriverTokens.spaceSm),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    Icons.event_seat_rounded,
                    DriverTokens.semanticSuccess,
                    'المقاعد الشاغرة',
                    '${trip.remainingSeats}',
                  ),
                ),
                const SizedBox(width: DriverTokens.spaceSm),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    Icons.payments_rounded,
                    DriverTokens.accentGold,
                    'سعر المقعد',
                    '${trip.price.toInt()} ${trip.currency}',
                  ),

                ),
              ],
            ),

            const SizedBox(height: DriverTokens.spaceMd),

            // Stops Timeline (Real Stops)
            Container(
              padding: const EdgeInsets.all(DriverTokens.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        color: DriverTokens.accentGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مسار الرحلة والمحطات (${trip.stops.length + 2})',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),

                  // Origin
                  _buildStopRow(
                    context,
                    trip.departureCity,
                    'نقطة الانطلاق',
                    isFirst: true,
                  ),

                  // Intermediate stops
                  ...trip.stops.map(
                    (stop) => _buildStopRow(
                      context,
                      stop.name,
                      [
                        if (stop.pickupAllowed) 'صعود',
                        if (stop.dropoffAllowed) 'نزول',
                      ].join(' و '),
                    ),
                  ),

                  // Destination
                  _buildStopRow(
                    context,
                    trip.arrivalCity,
                    'وجهة الوصول النهائية',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: DriverTokens.spaceMd),

            // Operational Shortcuts (Part 35)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/driver-bookings'),
                    icon: const Icon(Icons.people_outline_rounded, size: 18),
                    label: const Text(
                      'سجل الركاب والحضور',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/driver-support'),
                    icon: const Icon(
                      Icons.support_agent_rounded,
                      size: 18,
                      color: DriverTokens.semanticWarning,
                    ),
                    label: const Text(
                      'طلب مساعدة طارئة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: DriverTokens.semanticWarning,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: DriverTokens.semanticWarning,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: DriverTokens.spaceLg),

            // Finish Trip Button with confirmation
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _finishTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverTokens.semanticSuccess,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DriverTokens.radiusSmall,
                    ),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_rounded, size: 22),
                label: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'إنهاء الرحلة وتأكيد الوصول',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Cairo',
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStopRow(
    BuildContext context,
    String title,
    String subtitle, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst
                    ? DriverTokens.semanticSuccess
                    : isLast
                    ? DriverTokens.semanticError
                    : DriverTokens.accentGold,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Cairo',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
