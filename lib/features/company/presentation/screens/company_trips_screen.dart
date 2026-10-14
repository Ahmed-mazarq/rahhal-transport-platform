import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/company_trip_card.dart';

class CompanyTripsScreen extends StatefulWidget {
  const CompanyTripsScreen({super.key});

  @override
  State<CompanyTripsScreen> createState() => _CompanyTripsScreenState();
}

class _CompanyTripsScreenState extends State<CompanyTripsScreen> {
  String _selectedFilter = 'الكل';

  final List<String> _filters = [
    'الكل',
    'اليوم',
    'غداً',
    'هذا الأسبوع',
    'هذا الشهر',
    'مجدولة',
    'جارية',
    'مكتملة',
    'ملغاة',
    'مسودة',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: const Text(
            'إدارة الرحلات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (val) {},
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الرحلة، الوجهة، السائق، المركبة...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
              ),
            ),

            // Filters
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0B1F3A),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Trip List (Mock for now, should connect to Riverpod Provider)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3, // Mock count
                itemBuilder: (context, index) {
                  return CompanyTripCard(
                    tripNumber: 'TRP-100${index + 1}',
                    tripType: 'دولي',
                    origin: 'الرياض',
                    destination: 'صنعاء',
                    departureTime: '10:00 صباحاً - 20 أكتوبر',
                    arrivalTime: '08:00 مساءً - 21 أكتوبر',
                    assignedDriver: 'محمد عبدالله',
                    assignedVehicle: 'مرسيدس باص 2022',
                    totalSeats: 45,
                    reservedSeats: index == 0 ? 45 : 30,
                    price: 350.0,
                    status: index == 0 ? 'جارية' : 'مجدولة',
                    onViewDetails: () {},
                    onEdit: () {},
                    onDuplicate: () {},
                    onPauseBooking: () {},
                    onCancel: () {},
                    onDelete: () {},
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/company-trip-creation'),
          icon: const Icon(Icons.add),
          label: const Text(
            'إنشاء رحلة جديدة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0B1F3A),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
