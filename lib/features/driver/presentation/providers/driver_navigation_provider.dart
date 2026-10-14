import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central state provider for Driver Layout tab navigation (0: Home, 1: Trips, 2: Bookings, 3: Notifications, 4: Profile)
final driverTabIndexProvider = StateProvider<int>((ref) => 0);
