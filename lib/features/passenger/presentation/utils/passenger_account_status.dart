class PassengerAccountStatus {
  PassengerAccountStatus._();

  static String toArabic(String status) {
    switch (status.toLowerCase().trim()) {
      case 'active':
      case 'approved':
        return 'نشط';
      case 'pending':
      case 'pending_review':
        return 'قيد المراجعة';
      case 'blocked':
      case 'suspended':
        return 'موقوف';
      case 'need_modification':
        return 'يحتاج تعديل';
      case 'rejected':
        return 'مرفوض';
      case 'deleted':
        return 'محذوف';
      default:
        return 'غير معروف';
    }
  }
}
