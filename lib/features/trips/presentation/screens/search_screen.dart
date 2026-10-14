import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/passenger_search_provider.dart';
import 'package:rahal/core/theme/app_theme.dart';
import 'package:rahal/features/geo/domain/models/country.dart';
import 'package:rahal/features/geo/domain/models/governorate.dart';
import 'package:rahal/features/geo/domain/models/city.dart';
import 'package:rahal/features/geo/presentation/providers/geo_providers.dart';
import 'package:rahal/features/dashboard/presentation/providers/passenger_navigation_provider.dart';
import 'package:rahal/core/widgets/rahhal_app_bar.dart';
import '../widgets/passenger_location_picker_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _swapAnimController;

  @override
  void initState() {
    super.initState();
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      // Embedded in PassengerLayoutScreen: switch to Home tab
      ref.read(passengerTabIndexProvider.notifier).state = 0;
    }
  }

  void _onSwap() {
    HapticFeedback.selectionClick();
    if (_swapAnimController.status == AnimationStatus.completed) {
      _swapAnimController.reverse();
    } else {
      _swapAnimController.forward();
    }
    ref.read(passengerSearchFilterProvider.notifier).swapLocations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final searchState = ref.watch(passengerSearchFilterProvider);
    final searchNotifier = ref.read(passengerSearchFilterProvider.notifier);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: RahhalAppBar(
        titleText: 'بحث عن رحلة',
        onBackPressed: _handleBack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر تفاصيل رحلتك وسنبحث لك عن أفضل الخيارات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Main Journey Card (From / Swap / To)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // FROM Section
                    _buildDirectionSection(
                      icon: Icons.trip_origin_rounded,
                      iconColor: Colors.green,
                      label: 'من',
                      country: searchState.departureCountry,
                      province: searchState.departureProvince,
                      city: searchState.departureCity,
                      onCountryTap: () => _pickCountry(isDeparture: true),
                      onProvinceTap: () => _pickProvince(isDeparture: true),
                      onCityTap: () => _pickCity(isDeparture: true),
                      isDark: isDark,
                    ),

                    // Divider & Swap Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: InkWell(
                              onTap: _onSwap,
                              borderRadius: BorderRadius.circular(24),
                              child: RotationTransition(
                                turns: Tween(begin: 0.0, end: 0.5).animate(
                                  CurvedAnimation(
                                    parent: _swapAnimController,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accentGold.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentGold.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.swap_vert_rounded,
                                    color: accentGold,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TO Section
                    _buildDirectionSection(
                      icon: Icons.location_on_rounded,
                      iconColor: accentGold,
                      label: 'إلى',
                      country: searchState.arrivalCountry,
                      province: searchState.arrivalProvince,
                      city: searchState.arrivalCity,
                      onCountryTap: () => _pickCountry(isDeparture: false),
                      onProvinceTap: () => _pickProvince(isDeparture: false),
                      onCityTap: () => _pickCity(isDeparture: false),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date & Passenger Options Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Travel Date
                    _buildDateSelector(
                      travelDate: searchState.travelDate,
                      onTap: () => _pickTravelDate(searchState.travelDate),
                      onClear: () {
                        HapticFeedback.selectionClick();
                        searchNotifier.clearTravelDate();
                      },
                      isDark: isDark,
                      accentGold: accentGold,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                    ),

                    // Passenger Count Stepper
                    _buildPassengerStepper(
                      count: searchState.passengerCount,
                      onIncrement: () {
                        if (searchState.passengerCount < 20) {
                          HapticFeedback.selectionClick();
                          searchNotifier.setPassengerCount(
                            searchState.passengerCount + 1,
                          );
                        }
                      },
                      onDecrement: () {
                        if (searchState.passengerCount > 1) {
                          HapticFeedback.selectionClick();
                          searchNotifier.setPassengerCount(
                            searchState.passengerCount - 1,
                          );
                        }
                      },
                      isDark: isDark,
                      primaryNavy: primaryNavy,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Search CTA Button
              ElevatedButton(
                onPressed: _validateAndSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, color: accentGold, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'البحث عن الرحلات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionSection({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Country? country,
    required Governorate? province,
    required City? city,
    required VoidCallback onCountryTap,
    required VoidCallback onProvinceTap,
    required VoidCallback onCityTap,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Country & Province Selection Chips / Buttons
        Row(
          children: [
            // Country
            Expanded(
              flex: 5,
              child: _buildSelectorTile(
                hint: 'الدولة',
                value: country?.nameAr,
                onTap: onCountryTap,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            // Province / Governorate
            Expanded(
              flex: 6,
              child: _buildSelectorTile(
                hint: 'المحافظة',
                value: province?.nameAr,
                onTap: onProvinceTap,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Optional City Tile
        _buildSelectorTile(
          hint: 'المدينة (اختياري)',
          value: city?.nameAr,
          onTap: onCityTap,
          isDark: isDark,
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildSelectorTile({
    required String hint,
    required String? value,
    required VoidCallback onTap,
    required bool isDark,
    bool isOptional = false,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                : (isDark ? Colors.transparent : Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  color: hasValue
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[500] : Colors.grey[500]),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required DateTime? travelDate,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required bool isDark,
    required Color accentGold,
  }) {
    final hasDate = travelDate != null;
    final formattedDate = hasDate
        ? DateFormat('EEEE, d MMMM yyyy', 'ar').format(travelDate)
        : 'أي تاريخ';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: accentGold,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تاريخ السفر',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasDate)
          IconButton(
            tooltip: 'مسح التاريخ',
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            onPressed: onClear,
          )
        else
          Icon(
            Icons.chevron_left_rounded,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
      ],
    );
  }

  Widget _buildPassengerStepper({
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool isDark,
    required Color primaryNavy,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryNavy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.people_outline_rounded,
            color: primaryNavy,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عدد المسافرين',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? "مسافر" : "مسافرين"}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Stepper: - count +
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: count > 1 ? onDecrement : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFEAECEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 20,
                  color: count > 1
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[700] : Colors.grey[400]),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            InkWell(
              onTap: count < 20 ? onIncrement : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFEAECEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: count < 20
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[700] : Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTravelDate(DateTime? currentDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'اختر تاريخ السفر',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      ref.read(passengerSearchFilterProvider.notifier).setTravelDate(picked);
    }
  }

  void _pickCountry({required bool isDeparture}) {
    final searchNotifier = ref.read(passengerSearchFilterProvider.notifier);
    final currentState = ref.read(passengerSearchFilterProvider);
    final selectedId = isDeparture
        ? currentState.departureCountry?.id
        : currentState.arrivalCountry?.id;

    final countriesAsync = ref.read(countriesProvider);
    countriesAsync.when(
      data: (countries) async {
        final items = countries
            .map(
              (c) => PassengerLocationPickerItem(
                id: c.id,
                titleAr: c.nameAr,
                subtitle: c.nameEn,
              ),
            )
            .toList();

        final selected = await PassengerLocationPickerSheet.show(
          context: context,
          title: isDeparture ? 'اختر دولة الانطلاق' : 'اختر دولة الوصول',
          items: items,
          selectedId: selectedId,
        );

        if (selected != null) {
          final country = countries.firstWhere((c) => c.id == selected.id);
          if (isDeparture) {
            searchNotifier.setDepartureCountry(country);
          } else {
            searchNotifier.setArrivalCountry(country);
          }
        }
      },
      loading: () => _showWarning('جاري تحميل الدول...'),
      error: (_, _) => _showWarning('تعذر تحميل الدول، يرجى المحاولة لاحقاً'),
    );
  }

  void _pickProvince({required bool isDeparture}) {
    final searchState = ref.read(passengerSearchFilterProvider);
    final targetCountry = isDeparture
        ? searchState.departureCountry
        : searchState.arrivalCountry;

    if (targetCountry == null) {
      _showWarning(
        isDeparture
            ? 'يرجى اختيار دولة الانطلاق أولاً'
            : 'يرجى اختيار دولة الوصول أولاً',
      );
      return;
    }

    final searchNotifier = ref.read(passengerSearchFilterProvider.notifier);
    final selectedId = isDeparture
        ? searchState.departureProvince?.id
        : searchState.arrivalProvince?.id;

    final provincesAsync = ref.read(provincesProvider(targetCountry.id));
    provincesAsync.when(
      data: (provinces) async {
        final items = provinces
            .map(
              (p) => PassengerLocationPickerItem(
                id: p.id,
                titleAr: p.nameAr,
                subtitle: p.nameEn,
              ),
            )
            .toList();

        final selected = await PassengerLocationPickerSheet.show(
          context: context,
          title: isDeparture ? 'اختر محافظة الانطلاق' : 'اختر محافظة الوصول',
          items: items,
          selectedId: selectedId,
        );

        if (selected != null) {
          final province = provinces.firstWhere((p) => p.id == selected.id);
          if (isDeparture) {
            searchNotifier.setDepartureProvince(province);
          } else {
            searchNotifier.setArrivalProvince(province);
          }
        }
      },
      loading: () => _showWarning('جاري تحميل المحافظات...'),
      error: (_, _) =>
          _showWarning('تعذر تحميل المحافظات، يرجى المحاولة لاحقاً'),
    );
  }

  void _pickCity({required bool isDeparture}) {
    final searchState = ref.read(passengerSearchFilterProvider);
    final targetProvince = isDeparture
        ? searchState.departureProvince
        : searchState.arrivalProvince;

    if (targetProvince == null) {
      _showWarning(
        isDeparture
            ? 'يرجى اختيار محافظة الانطلاق أولاً'
            : 'يرجى اختيار محافظة الوصول أولاً',
      );
      return;
    }

    final searchNotifier = ref.read(passengerSearchFilterProvider.notifier);
    final selectedId = isDeparture
        ? searchState.departureCity?.id
        : searchState.arrivalCity?.id;

    final citiesAsync = ref.read(citiesProvider(targetProvince.id));
    citiesAsync.when(
      data: (cities) async {
        final items = cities
            .map(
              (c) => PassengerLocationPickerItem(
                id: c.id,
                titleAr: c.nameAr,
                subtitle: c.nameEn,
              ),
            )
            .toList();

        final selected = await PassengerLocationPickerSheet.show(
          context: context,
          title: isDeparture ? 'اختر مدينة الانطلاق' : 'اختر مدينة الوصول',
          items: items,
          selectedId: selectedId,
        );

        if (selected != null) {
          final city = cities.firstWhere((c) => c.id == selected.id);
          if (isDeparture) {
            searchNotifier.setDepartureCity(city);
          } else {
            searchNotifier.setArrivalCity(city);
          }
        }
      },
      loading: () => _showWarning('جاري تحميل المدن...'),
      error: (_, _) => _showWarning('تعذر تحميل المدن، يرجى المحاولة لاحقاً'),
    );
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _validateAndSearch() {
    final state = ref.read(passengerSearchFilterProvider);

    if (state.departureCountry == null) {
      _showWarning('اختر دولة الانطلاق');
      return;
    }
    if (state.departureProvince == null) {
      _showWarning('اختر محافظة الانطلاق');
      return;
    }
    if (state.arrivalCountry == null) {
      _showWarning('اختر دولة الوصول');
      return;
    }
    if (state.arrivalProvince == null) {
      _showWarning('اختر محافظة الوصول');
      return;
    }

    HapticFeedback.selectionClick();
    context.push('/search-results');
  }
}
