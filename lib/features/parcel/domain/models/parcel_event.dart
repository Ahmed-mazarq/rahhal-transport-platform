import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class ParcelEvent extends Equatable {
  final String id;
  final String parcelId;
  final String type; // e.g., 'status_change', 'offer_received'
  final String status;
  final String actorId;
  final String actorRole;
  final String description;
  final String? location;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const ParcelEvent({
    required this.id,
    required this.parcelId,
    required this.type,
    required this.status,
    required this.actorId,
    required this.actorRole,
    required this.description,
    this.location,
    this.metadata,
    required this.timestamp,
  });

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    return ParcelEvent(
      id: json['id'] as String? ?? '',
      parcelId: json['parcelId'] as String? ?? '',
      type: json['type'] as String? ?? 'status_change',
      status: json['status'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      actorRole: json['actorRole'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateParser.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parcelId': parcelId,
      'type': type,
      'status': status,
      'actorId': actorId,
      'actorRole': actorRole,
      'description': description,
      'location': location,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    parcelId,
    type,
    status,
    actorId,
    actorRole,
    description,
    location,
    metadata,
    timestamp,
  ];
}
