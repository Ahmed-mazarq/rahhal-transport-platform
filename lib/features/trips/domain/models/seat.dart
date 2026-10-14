import 'package:equatable/equatable.dart';

class Seat extends Equatable {
  final String id;
  final String number;
  final String status; // available, blocked, booked
  final bool isVip;
  final bool isWomenOnly;
  final bool isDisabled;
  final int row;
  final int column;

  const Seat({
    required this.id,
    required this.number,
    this.status = 'available',
    this.isVip = false,
    this.isWomenOnly = false,
    this.isDisabled = false,
    required this.row,
    required this.column,
  });

  Seat copyWith({
    String? id,
    String? number,
    String? status,
    bool? isVip,
    bool? isWomenOnly,
    bool? isDisabled,
    int? row,
    int? column,
  }) {
    return Seat(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      isVip: isVip ?? this.isVip,
      isWomenOnly: isWomenOnly ?? this.isWomenOnly,
      isDisabled: isDisabled ?? this.isDisabled,
      row: row ?? this.row,
      column: column ?? this.column,
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'available',
      isVip: _parseBool(json['isVip'], false),
      isWomenOnly: _parseBool(json['isWomenOnly'], false),
      isDisabled: _parseBool(json['isDisabled'], false),
      row: _parseInt(json['row'], 0),
      column: _parseInt(json['column'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'isVip': isVip,
      'isWomenOnly': isWomenOnly,
      'isDisabled': isDisabled,
      'row': row,
      'column': column,
    };
  }

  @override
  List<Object?> get props => [
    id,
    number,
    status,
    isVip,
    isWomenOnly,
    isDisabled,
    row,
    column,
  ];
}
