import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/system_config_provider.dart';
import '../providers/passenger_navigation_provider.dart';

class PassengerQuickActions extends ConsumerWidget {
  const PassengerQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider).value ?? {};
    final isParcelEnabled = flags['parcel_delivery'] != false;
    final isSupportEnabled = flags['support_chat'] != false;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = <_QuickActionItem>[
      _QuickActionItem(
        label: 'حجز رحلة',
        icon: Icons.directions_car_rounded,
        route: '/search',
        color: const Color(0xFF0B1F3A),
        iconColor: const Color(0xFFF5A623),
      ),
      if (isParcelEnabled)
        _QuickActionItem(
          label: 'إرسال طرد',
          icon: Icons.inventory_2_rounded,
          route: '/parcel-booking',
          color: const Color(0xFF0B1F3A),
          iconColor: const Color(0xFF4A90E2),
        ),
      _QuickActionItem(
        label: 'تتبع رحلة',
        icon: Icons.location_on_rounded,
        route: '/passenger-tracking',
        color: const Color(0xFF0B1F3A),
        iconColor: const Color(0xFF27AE60),
      ),
      if (isSupportEnabled)
        _QuickActionItem(
          label: 'الدعم',
          icon: Icons.support_agent_rounded,
          route: '/support',
          color: const Color(0xFF0B1F3A),
          iconColor: const Color(0xFFE67E22),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // If on very narrow screens (< 340), or if parcel & support are both present
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _QuickActionTile(item: item, isDark: isDark),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final Color iconColor;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
    required this.iconColor,
  });
}

class _QuickActionTile extends ConsumerWidget {
  final _QuickActionItem item;
  final bool isDark;

  const _QuickActionTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileBg = isDark ? const Color(0xFF141F30) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF0B1F3A).withValues(alpha: 0.05);

    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (item.route == '/search') {
              ref.read(passengerTabIndexProvider.notifier).state = 1;
            } else {
              context.push(item.route);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 78),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : const Color(0xFF0B1F3A).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
