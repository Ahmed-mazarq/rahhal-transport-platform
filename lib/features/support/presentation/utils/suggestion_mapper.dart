import 'package:flutter/material.dart';

class SuggestionMapper {
  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'chat':
        return Icons.chat;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'add_circle_outline':
        return Icons.add_circle_outline;
      case 'report_problem':
        return Icons.report_problem;
      case 'help_outline':
        return Icons.help_outline;
      case 'contact_support':
        return Icons.contact_support;
      case 'headset_mic':
        return Icons.headset_mic;
      case 'drive_eta':
        return Icons.drive_eta;
      case 'business':
        return Icons.business;
      default:
        return Icons.extension; // Fallback
    }
  }

  static Color getColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'teal':
        return Colors.teal;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.grey; // Fallback
    }
  }
}
