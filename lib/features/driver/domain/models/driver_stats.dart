import 'package:equatable/equatable.dart';

class DriverStats extends Equatable {
  final int publishedTrips;
  final int currentPassengers;
  final double? averageRating;
  final int newBookings;
  final int todaysTrips;
  final int thisWeekTrips;
  final int thisMonthTrips;
  final int completedTrips;
  final int cancelledTrips;
  final double? commitmentRate;
  final double occupancyRate;
  final double revenue; // Informational only

  const DriverStats({
    this.publishedTrips = 0,
    this.currentPassengers = 0,
    this.averageRating,
    this.newBookings = 0,
    this.todaysTrips = 0,
    this.thisWeekTrips = 0,
    this.thisMonthTrips = 0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    this.commitmentRate,
    this.occupancyRate = 0.0,
    this.revenue = 0.0,
  });

  DriverStats copyWith({
    int? publishedTrips,
    int? currentPassengers,
    double? averageRating,
    int? newBookings,
    int? todaysTrips,
    int? thisWeekTrips,
    int? thisMonthTrips,
    int? completedTrips,
    int? cancelledTrips,
    double? commitmentRate,
    double? occupancyRate,
    double? revenue,
  }) {
    return DriverStats(
      publishedTrips: publishedTrips ?? this.publishedTrips,
      currentPassengers: currentPassengers ?? this.currentPassengers,
      averageRating: averageRating ?? this.averageRating,
      newBookings: newBookings ?? this.newBookings,
      todaysTrips: todaysTrips ?? this.todaysTrips,
      thisWeekTrips: thisWeekTrips ?? this.thisWeekTrips,
      thisMonthTrips: thisMonthTrips ?? this.thisMonthTrips,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      commitmentRate: commitmentRate ?? this.commitmentRate,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      revenue: revenue ?? this.revenue,
    );
  }

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      publishedTrips: (json['publishedTrips'] as num?)?.toInt() ?? 0,
      currentPassengers: (json['currentPassengers'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      newBookings: (json['newBookings'] as num?)?.toInt() ?? 0,
      todaysTrips: (json['todaysTrips'] as num?)?.toInt() ?? 0,
      thisWeekTrips: (json['thisWeekTrips'] as num?)?.toInt() ?? 0,
      thisMonthTrips: (json['thisMonthTrips'] as num?)?.toInt() ?? 0,
      completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
      cancelledTrips: (json['cancelledTrips'] as num?)?.toInt() ?? 0,
      commitmentRate: (json['commitmentRate'] as num?)?.toDouble(),
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publishedTrips': publishedTrips,
      'currentPassengers': currentPassengers,
      'averageRating': averageRating,
      'newBookings': newBookings,
      'todaysTrips': todaysTrips,
      'thisWeekTrips': thisWeekTrips,
      'thisMonthTrips': thisMonthTrips,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'commitmentRate': commitmentRate,
      'occupancyRate': occupancyRate,
      'revenue': revenue,
    };
  }

  @override
  List<Object?> get props => [
    publishedTrips,
    currentPassengers,
    averageRating,
    newBookings,
    todaysTrips,
    thisWeekTrips,
    thisMonthTrips,
    completedTrips,
    cancelledTrips,
    commitmentRate,
    occupancyRate,
    revenue,
  ];
}
