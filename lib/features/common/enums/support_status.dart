enum SupportStatus { open, waiting, processing, resolved, closed, rejected }

extension SupportStatusExtension on SupportStatus {
  String get value {
    switch (this) {
      case SupportStatus.open:
        return 'open';
      case SupportStatus.waiting:
        return 'waiting';
      case SupportStatus.processing:
        return 'processing';
      case SupportStatus.resolved:
        return 'resolved';
      case SupportStatus.closed:
        return 'closed';
      case SupportStatus.rejected:
        return 'rejected';
    }
  }

  static SupportStatus fromString(String val) {
    switch (val) {
      case 'open':
      case 'pending':
        return SupportStatus.open;
      case 'waiting':
        return SupportStatus.waiting;
      case 'processing':
      case 'inProgress':
      case 'in_investigation':
        return SupportStatus.processing;
      case 'resolved':
      case 'solved':
        return SupportStatus.resolved;
      case 'closed':
        return SupportStatus.closed;
      case 'rejected':
        return SupportStatus.rejected;
      default:
        return SupportStatus.open;
    }
  }
}
