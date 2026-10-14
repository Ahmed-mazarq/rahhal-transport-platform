import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../widgets/vehicle_card.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/driver_providers.dart';
import '../utils/driver_tokens.dart';

class DriverVehiclesScreen extends ConsumerStatefulWidget {
  const DriverVehiclesScreen({super.key});

  @override
  ConsumerState<DriverVehiclesScreen> createState() =>
      _DriverVehiclesScreenState();
}

class _DriverVehiclesScreenState extends ConsumerState<DriverVehiclesScreen> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;
    final uid = authState.user.uid;

    try {
      final repo = ref.read(fleetRepositoryProvider);
      // Canonical migration moved safely to repository layer
      await repo.ensureLegacyVehicleMigrated(uid);
      final vehicles = await repo.getDriverVehicles(uid);

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    // Check for active trips connected to this vehicle
    final tripRepo = ref.read(tripRepositoryProvider);
    final trips = await tripRepo.getDriverTrips(authState.user.uid);
    final activeTrips = trips
        .where(
          (t) =>
              t.vehiclePlate == vehicle.plateNumber &&
              (t.status == 'published' ||
                  t.status == 'open_for_booking' ||
                  t.status == 'running'),
        )
        .toList();

    if (activeTrips.isNotEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'تعذر الحذف',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: const Text(
            'لا يمكن حذف هذه المركبة لوجود رحلات نشطة مرتبطة بها.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final repo = ref.read(fleetRepositoryProvider);
      await repo.deleteVehicle(vehicle.id);
      await _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف المركبة بنجاح',
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
              'تعذر حذف المركبة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    }
  }

  Future<void> _setPrimary(Vehicle vehicle) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.setPrimaryVehicle(authState.user.uid, vehicle.id);
      // Invalidate profile so primary badge reflects immediately
      ref.invalidate(driverProfileProvider);
      await _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تعيين المركبة كمركبة أساسية',
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
              'تعذر تعيين المركبة الأساسية',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    }
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int totalCount = _vehicles.length;
    final int availableCount = _vehicles
        .where((v) => v.status == 'Available')
        .length;
    final int inServiceCount = _vehicles
        .where((v) => v.status == 'In Service')
        .length;
    final int maintenanceCount = _vehicles
        .where((v) => v.status == 'Maintenance')
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
      padding: const EdgeInsets.all(DriverTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_filled_rounded,
                color: DriverTokens.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ملخص أسطول المركبات',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDashItem(
                context,
                Icons.directions_car_rounded,
                'الإجمالي',
                totalCount.toString(),
                DriverTokens.semanticInfo,
              ),
              _buildDashItem(
                context,
                Icons.check_circle_rounded,
                'متاحة',
                availableCount.toString(),
                DriverTokens.semanticSuccess,
              ),
              _buildDashItem(
                context,
                Icons.alt_route_rounded,
                'في الخدمة',
                inServiceCount.toString(),
                DriverTokens.accentGold,
              ),
              _buildDashItem(
                context,
                Icons.build_circle_rounded,
                'صيانة',
                maintenanceCount.toString(),
                DriverTokens.semanticWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashItem(
    BuildContext context,
    IconData icon,
    String label,
    String val,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101928)
            : DriverTokens.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101928) : Colors.white,
          elevation: 0,
          title: const Text(
            'مركباتي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
              onPressed: () {
                setState(() => _isLoading = true);
                _loadVehicles();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _vehicles.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(DriverTokens.spaceXl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: DriverTokens.spaceMd),
                      Text(
                        'لم تضف أي مركبة بعد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: DriverTokens.spaceXs),
                      Text(
                        'أضف مركبتك لتتمكن من إنشاء رحلات واستقبال الحجوزات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: DriverTokens.spaceLg),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/add-vehicle');
                          _loadVehicles();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'إضافة مركبة الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverTokens.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DriverTokens.radiusSmall,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadVehicles,
                child: ListView.builder(
                  padding: const EdgeInsets.all(DriverTokens.spaceMd),
                  itemCount: _vehicles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildDashboard(context);
                    final vehicle = _vehicles[index - 1];
                    return Consumer(
                      builder: (context, ref, _) {
                        final profileAsync = ref.watch(driverProfileProvider);
                        final profile = profileAsync.value;
                        final isPrimary =
                            profile?.primaryVehicleId == vehicle.id;

                        return VehicleCard(
                          vehicle: vehicle,
                          isPrimary: isPrimary,
                          onTap: () async {
                            await context.push(
                              '/vehicle-details/${vehicle.id}',
                              extra: vehicle,
                            );
                            _loadVehicles();
                          },
                          onEdit: () async {
                            await context.push('/add-vehicle', extra: vehicle);
                            _loadVehicles();
                          },
                          onDelete: () => _deleteVehicle(vehicle),
                          onSetPrimary: () => _setPrimary(vehicle),
                        );
                      },
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/add-vehicle');
            _loadVehicles();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إضافة مركبة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: DriverTokens.primaryNavy,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
