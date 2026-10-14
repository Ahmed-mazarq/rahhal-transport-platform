import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../parcel/presentation/providers/parcel_provider.dart';
import '../../../parcel/domain/models/parcel_delivery.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';

class DriverParcelMarketplaceScreen extends ConsumerWidget {
  const DriverParcelMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(
          child: Text(
            'يرجى تسجيل الدخول لعرض سوق الطرود',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    final driverId = authState.user.uid;
    final driverName = authState.user.fullName;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF101928)
              : DriverTokens.lightBackground,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF101928) : Colors.white,
            foregroundColor: isDark ? Colors.white : DriverTokens.primaryNavy,
            elevation: 0,
            title: const Text(
              'سوق الطرود والشحنات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            bottom: TabBar(
              indicatorColor: DriverTokens.accentGold,
              labelColor: DriverTokens.accentGold,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'الطرود المتاحة'),
                Tab(text: 'الطرود النشطة'),
                Tab(text: 'سجل التسليم'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'تحديث',
                onPressed: () {
                  ref.invalidate(marketplaceParcelsProvider);
                  ref.invalidate(matchedMarketplaceParcelsProvider(driverId));
                  ref.invalidate(driverParcelsProvider(driverId));
                },
              ),
            ],
          ),
          body: TabBarView(
            children: [
              _buildMarketplaceTab(context, ref, driverId, driverName),
              _buildActiveParcelsTab(context, ref, driverId),
              _buildHistoryParcelsTab(context, ref, driverId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceTab(
    BuildContext context,
    WidgetRef ref,
    String driverId,
    String driverName,
  ) {
    final theme = Theme.of(context);
    final matchedParcelsAsync = ref.watch(
      matchedMarketplaceParcelsProvider(driverId),
    );

    return matchedParcelsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DriverTokens.accentGold),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: DriverTokens.semanticError,
            ),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل الطرود المتاحة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(matchedMarketplaceParcelsProvider(driverId)),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
      data: (matchedParcels) {
        if (matchedParcels.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(DriverTokens.spaceXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),
                  Text(
                    'لا توجد طرود مناسبة حالياً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceXs),
                  Text(
                    'ستظهر هنا الطرود المتوافقة مع مسارات رحلاتك القادمة ومناطق عملك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DriverTokens.spaceMd),
          itemCount: matchedParcels.length,
          itemBuilder: (context, index) {
            final match = matchedParcels[index];
            return _buildParcelCard(
              context,
              ref,
              match.parcel,
              driverId,
              driverName,
              isMarketplace: true,
              matchReason: match.matchReason,
              score: match.score,
            );
          },
        );
      },
    );
  }

  Widget _buildActiveParcelsTab(
    BuildContext context,
    WidgetRef ref,
    String driverId,
  ) {
    final theme = Theme.of(context);
    final driverParcelsAsync = ref.watch(driverParcelsProvider(driverId));

    return driverParcelsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DriverTokens.accentGold),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: DriverTokens.semanticError,
            ),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل الطرود النشطة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(driverParcelsProvider(driverId)),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
      data: (parcels) {
        final activeParcels = parcels
            .where(
              (p) => [
                'accepted',
                'awaiting_pickup',
                'picked_up',
                'in_transit',
                'ready_for_delivery',
              ].contains(p.status),
            )
            .toList();

        if (activeParcels.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(DriverTokens.spaceXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),
                  Text(
                    'ليس لديك أي طرود نشطة حالياً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceXs),
                  Text(
                    'تصفح سوق الطرود المتاحة لقبول شحنات جديدة وزيادة دخلك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DriverTokens.spaceMd),
          itemCount: activeParcels.length,
          itemBuilder: (context, index) {
            return _buildParcelCard(
              context,
              ref,
              activeParcels[index],
              driverId,
              '',
              isMarketplace: false,
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryParcelsTab(
    BuildContext context,
    WidgetRef ref,
    String driverId,
  ) {
    final theme = Theme.of(context);
    final driverParcelsAsync = ref.watch(driverParcelsProvider(driverId));

    return driverParcelsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DriverTokens.accentGold),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: DriverTokens.semanticError,
            ),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل سجل الطرود',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(driverParcelsProvider(driverId)),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
      data: (parcels) {
        final historyParcels = parcels
            .where(
              (p) => [
                'delivered',
                'completed',
                'rejected',
                'cancelled',
              ].contains(p.status),
            )
            .toList();

        if (historyParcels.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(DriverTokens.spaceXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),
                  Text(
                    'لا يوجد سجل طرود سابقة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceXs),
                  Text(
                    'الطرود المكتملة والمسلمة ستظهر هنا كأرشيف دائم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DriverTokens.spaceMd),
          itemCount: historyParcels.length,
          itemBuilder: (context, index) {
            return _buildParcelCard(
              context,
              ref,
              historyParcels[index],
              driverId,
              '',
              isMarketplace: false,
            );
          },
        );
      },
    );
  }

  Widget _buildParcelCard(
    BuildContext context,
    WidgetRef ref,
    ParcelDelivery parcel,
    String driverId,
    String driverName, {
    required bool isMarketplace,
    String matchReason = '',
    int score = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusUi = ParcelStatusUi.fromStatus(parcel.status);

    return Card(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        side: BorderSide(
          color: (isMarketplace && score > 50)
              ? DriverTokens.accentGold
              : (isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.05)),
          width: (isMarketplace && score > 50) ? 1.5 : 1.0,
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        onTap: () {
          context.push('/parcel-details/${parcel.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(DriverTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isMarketplace)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: score > 50
                            ? DriverTokens.accentGold.withValues(alpha: 0.15)
                            : DriverTokens.semanticInfo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        matchReason.isNotEmpty ? matchReason : 'طرد متاح',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: score > 50
                              ? DriverTokens.accentGold
                              : DriverTokens.semanticInfo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusUi.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusUi.icon, color: statusUi.color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            statusUi.label,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: statusUi.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    formatCurrencyAmount(parcel.price, parcel.currency),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DriverTokens.accentGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'من: ${parcel.originProvince.isNotEmpty ? parcel.originProvince : parcel.originCity}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'إلى: ${parcel.destinationProvince.isNotEmpty ? parcel.destinationProvince : parcel.destinationCity}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    parcel.category,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (parcel.isFragile) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'قابل للكسر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${parcel.weight} كجم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (isMarketplace) ...[
                const SizedBox(height: DriverTokens.spaceMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTokens.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusSmall,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    onPressed: () => _acceptParcel(
                      context,
                      ref,
                      parcel.id,
                      driverId,
                      driverName,
                    ),
                    label: const Text(
                      'قبول التوصيل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _acceptParcel(
    BuildContext context,
    WidgetRef ref,
    String parcelId,
    String driverId,
    String driverName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد القبول',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في نقل وتوصيل هذا الطرد؟',
          style: TextStyle(fontFamily: 'Cairo'),
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
              'تأكيد القبول',
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
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final success = await ref
        .read(parcelActionProvider.notifier)
        .acceptParcel(parcelId, driverId, driverName);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم قبول الطرد بنجاح!',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticSuccess,
        ),
      );
      context.push('/parcel-details/$parcelId');
    } else {
      final error = ref.read(parcelActionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error?.toString() ?? 'تعذر قبول الطرد، يرجى المحاولة لاحقاً',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticError,
        ),
      );
    }
  }
}
