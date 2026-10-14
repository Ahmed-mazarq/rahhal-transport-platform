import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleAwareNotificationNavigator {
  RoleAwareNotificationNavigator._();

  static const List<String> _passengerAllowedPrefixes = [
    '/booking-details/',
    '/trip-details/',
    '/parcel-details/',
    '/support',
    '/offers',
    '/passenger-tracking',
    '/my-bookings',
  ];

  static const List<String> _driverAllowedPrefixes = [
    '/driver-booking-details/',
    '/driver-trip-details/',
    '/parcel-details/',
    '/driver-support',
    '/driver-trips',
    '/driver-bookings',
    '/driver-documents',
    '/driver-vehicles',
    '/payment-methods',
  ];

  /// Safely resolves and navigates from notification payload based on user role
  static void navigate(
    BuildContext context,
    Map<String, dynamic> payload, {
    String role = 'passenger',
  }) {
    if (payload.isEmpty) return;

    if (role == 'driver') {
      _navigateDriver(context, payload);
    } else {
      _navigatePassenger(context, payload);
    }
  }

  static void _navigateDriver(
    BuildContext context,
    Map<String, dynamic> payload,
  ) {
    // 1. Direct Entity ID Mappings
    final bookingId = payload['bookingId']?.toString();
    if (bookingId != null && bookingId.isNotEmpty) {
      context.push('/driver-booking-details/$bookingId');
      return;
    }

    final tripId = payload['tripId']?.toString();
    if (tripId != null && tripId.isNotEmpty) {
      context.push('/driver-trip-details/$tripId');
      return;
    }

    final parcelId = payload['parcelId']?.toString();
    if (parcelId != null && parcelId.isNotEmpty) {
      context.push('/parcel-details/$parcelId');
      return;
    }

    final ticketId =
        payload['ticketId']?.toString() ??
        payload['conversationId']?.toString();
    if (ticketId != null && ticketId.isNotEmpty) {
      context.push('/driver-support');
      return;
    }

    // 2. Category / Type fallback
    final type =
        payload['type']?.toString().toLowerCase() ??
        payload['category']?.toString().toLowerCase();

    if (type == 'booking' || type == 'payment') {
      context.push('/driver-bookings');
      return;
    } else if (type == 'trip') {
      context.push('/driver-trips');
      return;
    } else if (type == 'parcel') {
      context.push('/driver-parcels');
      return;
    } else if (type == 'support') {
      context.push('/driver-support');
      return;
    } else if (type == 'document') {
      context.push('/driver-documents');
      return;
    } else if (type == 'vehicle') {
      context.push('/driver-vehicles');
      return;
    }

    // 3. Allowlisted Route String
    final route = payload['route']?.toString();
    if (route != null && route.isNotEmpty) {
      final isAllowed = _driverAllowedPrefixes.any(
        (prefix) => route.startsWith(prefix),
      );
      if (isAllowed) {
        context.push(route);
        return;
      }
    }
  }

  static void _navigatePassenger(
    BuildContext context,
    Map<String, dynamic> payload,
  ) {
    // 1. Direct Entity ID Mappings
    final bookingId = payload['bookingId']?.toString();
    if (bookingId != null && bookingId.isNotEmpty) {
      context.push('/booking-details/$bookingId');
      return;
    }

    final tripId = payload['tripId']?.toString();
    if (tripId != null && tripId.isNotEmpty) {
      context.push('/trip-details/$tripId');
      return;
    }

    final parcelId = payload['parcelId']?.toString();
    if (parcelId != null && parcelId.isNotEmpty) {
      context.push('/parcel-details/$parcelId');
      return;
    }

    final ticketId =
        payload['ticketId']?.toString() ??
        payload['conversationId']?.toString();
    if (ticketId != null && ticketId.isNotEmpty) {
      context.push('/support');
      return;
    }

    // 2. Type-based Fallback
    final type =
        payload['type']?.toString().toLowerCase() ??
        payload['category']?.toString().toLowerCase();

    if (type == 'promotion' || type == 'offer') {
      context.push('/offers');
      return;
    } else if (type == 'support') {
      context.push('/support');
      return;
    } else if (type == 'booking') {
      context.push('/my-bookings');
      return;
    }

    // 3. Strict Allowlisted Route String
    final route = payload['route']?.toString();
    if (route != null && route.isNotEmpty) {
      final isAllowed = _passengerAllowedPrefixes.any(
        (prefix) => route.startsWith(prefix),
      );
      if (isAllowed) {
        context.push(route);
        return;
      }
    }
  }
}
