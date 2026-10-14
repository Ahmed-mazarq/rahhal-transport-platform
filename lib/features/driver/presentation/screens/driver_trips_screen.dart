import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/models/trip.dart';
import '../widgets/driver_trip_card.dart';
import '../utils/driver_tokens.dart';

class DriverTripsScreen extends ConsumerStatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  ConsumerState<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends ConsumerState<DriverTripsScreen> {
  List<Trip> _allTrips = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _filters = const [
    {'id': 'all', 'label': 'الكل'},
    {'id': 'draft', 'label': 'مسودات'},
    {'id': 'published', 'label': 'منشورة'},
    {'id': 'open_for_booking', 'label': 'متاحة للحجز'},
    {'id': 'running', 'label': 'جارية الآن'},
    {'id': 'completed', 'label': 'مكتملة'},
    {'id': 'cancelled', 'label': 'ملغاة'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDriverTrips();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDriverTrips() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final trips = await tripRepo.getDriverTrips(authState.user.uid);

      // Sort by departureTime descending
      trips.sort((a, b) => b.departureTime.compareTo(a.departureTime));

      if (mounted) {
        setState(() {
          _allTrips = trips;
        });
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelTrip(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء الرحلة'),
          content: const Text(
            'هل أنت متأكد من رغبتك في إلغاء هذه الرحلة؟ سيتم إشعار الركاب الحاجزين بذلك.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTokens.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('نعم، إلغاء الرحلة'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      await tripRepo.updateTripStatus(tripId, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الرحلة بنجاح'),
            backgroundColor: DriverTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadDriverTrips();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إلغاء الرحلة، يرجى المحاولة لاحقاً'),
            backgroundColor: DriverTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _duplicateTrip(Trip trip) async {
    setState(() => _isLoading = true);
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final dupId = 'tr_${DateTime.now().millisecondsSinceEpoch}';
      final duplicated = trip.copyWith(
        id: dupId,
        departureTime: DateTime.now().add(const Duration(days: 1)),
        arrivalTime: DateTime.now().add(const Duration(days: 1, hours: 8)),
        status: 'draft',
        remainingSeats: trip.totalSeats,
        createdAt: DateTime.now(),
      );
      await tripRepo.createTrip(duplicated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تكرار الرحلة كمسودة بنجاح'),
            backgroundColor: DriverTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadDriverTrips();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تكرار الرحلة'),
            backgroundColor: DriverTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<Trip> _getFilteredTrips() {
    return _allTrips.where((t) {
      // 1. Status Filter
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'running') {
          final isRunning =
              t.status == 'running' ||
              t.status == 'active' ||
              t.status == 'started';
          if (!isRunning) return false;
        } else if (t.status != _selectedFilter) {
          return false;
        }
      }

      // 2. Real Local Search Query (Part 16)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        final matchesDeparture = t.departureCity.toLowerCase().contains(query);
        final matchesArrival = t.arrivalCity.toLowerCase().contains(query);
        final matchesPlate = t.vehiclePlate.toLowerCase().contains(query);
        final matchesId = t.id.toLowerCase().contains(query);
        final matchesBrand = t.vehicleBrand.toLowerCase().contains(query);

        if (!matchesDeparture &&
            !matchesArrival &&
            !matchesPlate &&
            !matchesId &&
            !matchesBrand) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredTrips = _getFilteredTrips();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : DriverTokens.backgroundLight,
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'ابحث بالمدينة، المركبة، رقم الرحلة...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                )
              : const Text(
                  'إدارة رحلاتي',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
          centerTitle: !_isSearching,
          backgroundColor: isDark ? DriverTokens.cardDark : Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
              ),
              tooltip: _isSearching ? 'إغلاق البحث' : 'بحث في الرحلات',
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'إنشاء رحلة جديدة',
              onPressed: () => context.push('/create-trip'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Status Filters Row
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: isDark ? DriverTokens.cardDark : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter['id'];

                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FilterChip(
                      label: Text(
                        filter['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: DriverTokens.primaryNavy,
                      backgroundColor: isDark
                          ? const Color(0xFF252525)
                          : const Color(0xFFF0F2F5),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter['id']!);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? DriverTokens.primaryNavy
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Trips List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDriverTrips,
                color: DriverTokens.primaryNavy,
                child: _isLoading && _allTrips.isEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: 4,
                        itemBuilder: (_, _) => Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DriverTokens.cardDark
                                : Colors.white,
                            borderRadius: DriverTokens.borderCard,
                          ),
                        ),
                      )
                    : filteredTrips.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'لا توجد نتائج بحث مطابقة'
                                    : 'لا توجد رحلات في هذا التبويب',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'جرّب البحث باسم مدينة أخرى أو رقم الرحلة'
                                    : 'ابدأ بإنشاء رحلة جديدة لعرضها للمسافرين',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/create-trip'),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('إنشاء رحلة جديدة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DriverTokens.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) {
                          final trip = filteredTrips[index];
                          return DriverTripCard(
                            trip: trip,
                            onViewDetails: () {
                              if (trip.status == 'running') {
                                context.push('/driver-live-trip', extra: trip);
                              } else {
                                context.push(
                                  '/driver-trip-details/${trip.id}',
                                  extra: trip,
                                );
                              }
                            },
                            onEdit: () =>
                                context.push('/create-trip', extra: trip),
                            onDuplicate: () => _duplicateTrip(trip),
                            onCancel: () => _cancelTrip(trip.id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
