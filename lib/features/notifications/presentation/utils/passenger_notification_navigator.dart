import 'package:flutter/material.dart';
import 'role_aware_notification_navigator.dart';

/// Legacy adapter forwarding to RoleAwareNotificationNavigator
class PassengerNotificationNavigator {
  PassengerNotificationNavigator._();

  static void navigate(BuildContext context, Map<String, dynamic> payload) {
    RoleAwareNotificationNavigator.navigate(context, payload, role: 'passenger');
  }
}
