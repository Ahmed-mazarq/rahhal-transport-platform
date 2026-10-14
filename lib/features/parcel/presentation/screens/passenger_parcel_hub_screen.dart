import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'parcel_booking_screen.dart';
import 'parcel_tracking_screen.dart';

class PassengerParcelHubScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const PassengerParcelHubScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<PassengerParcelHubScreen> createState() =>
      _PassengerParcelHubScreenState();
}

class _PassengerParcelHubScreenState
    extends ConsumerState<PassengerParcelHubScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _switchToTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'الطرود',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'إرسال ومتابعة طرودك بسهولة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'إرسال طرد',
                      icon: Icons.inventory_2_rounded,
                      isActive: _currentIndex == 0,
                      onTap: () => _switchToTab(0),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'تتبع طرودي',
                      icon: Icons.track_changes_rounded,
                      isActive: _currentIndex == 1,
                      onTap: () => _switchToTab(1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentIndex == 0
            ? const ParcelBookingScreen(isEmbedded: true)
            : ParcelTrackingScreen(onSendNewParcel: () => _switchToTab(0)),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF0B1F3A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(21),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFFF5A623)
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: isActive
                    ? const Color(0xFFF5A623)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
