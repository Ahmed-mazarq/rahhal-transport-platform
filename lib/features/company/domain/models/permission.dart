import 'package:equatable/equatable.dart';

class Permission extends Equatable {
  final String resource; // e.g. trips, bookings, vehicles
  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canApprove;
  final bool canExport;

  const Permission({
    required this.resource,
    this.canView = false,
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canApprove = false,
    this.canExport = false,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      resource: json['resource'] as String? ?? '',
      canView: json['canView'] as bool? ?? false,
      canCreate: json['canCreate'] as bool? ?? false,
      canEdit: json['canEdit'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
      canApprove: json['canApprove'] as bool? ?? false,
      canExport: json['canExport'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resource': resource,
      'canView': canView,
      'canCreate': canCreate,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canApprove': canApprove,
      'canExport': canExport,
    };
  }

  @override
  List<Object?> get props => [
    resource,
    canView,
    canCreate,
    canEdit,
    canDelete,
    canApprove,
    canExport,
  ];
}
