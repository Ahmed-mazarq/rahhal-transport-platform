import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central provider for Passenger bottom navigation index:
/// 0 = Home (الرئيسية)
/// 1 = Search (بحث)
/// 2 = My Bookings (حجوزاتي)
/// 3 = Notifications (إشعارات)
/// 4 = Profile (حسابي)
final passengerTabIndexProvider = StateProvider<int>((ref) => 0);
