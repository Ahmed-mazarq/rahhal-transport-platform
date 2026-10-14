class AnalyticsRange {
  final DateTime start;
  final DateTime end;
  final String label;

  AnalyticsRange({required this.start, required this.end, required this.label});
}

class AnalyticsComparison {
  final num current;
  final num previous;

  AnalyticsComparison({required this.current, required this.previous});

  bool get isNew => previous == 0 && current > 0;

  double get percentageChange {
    if (previous == 0 && current == 0) return 0.0;
    if (previous == 0 && current > 0) return 100.0;
    return ((current - previous) / previous) * 100;
  }
}

class DashboardKPIs {
  final int totalPassengers;
  final int totalDrivers;
  final int totalCompanies;
  final int totalVehicles;
  final int totalTrips;
  final int totalBookings;

  final AnalyticsComparison passengersChange;
  final AnalyticsComparison driversChange;
  final AnalyticsComparison companiesChange;

  final int periodTrips;
  final int periodBookings;

  final int completedTrips;
  final int cancelledTrips;
  final int completedBookings;
  final int cancelledBookings;

  final double cancellationRate;
  final double seatOccupancyRate;
  final double averageDriverRating;

  final int onlineDrivers;
  final int activeCompanies;
  final int pendingDocuments;
  final int openSupportTickets;

  final Map<String, double> averageTripPriceByCurrency;

  DashboardKPIs({
    required this.totalPassengers,
    required this.totalDrivers,
    required this.totalCompanies,
    required this.totalVehicles,
    required this.totalTrips,
    required this.totalBookings,

    required this.passengersChange,
    required this.driversChange,
    required this.companiesChange,

    required this.periodTrips,
    required this.periodBookings,

    required this.completedTrips,
    required this.cancelledTrips,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.cancellationRate,
    required this.seatOccupancyRate,
    required this.averageDriverRating,
    required this.onlineDrivers,
    required this.activeCompanies,
    required this.pendingDocuments,
    required this.openSupportTickets,
    required this.averageTripPriceByCurrency,
  });

  factory DashboardKPIs.empty() => DashboardKPIs(
    totalPassengers: 0,
    totalDrivers: 0,
    totalCompanies: 0,
    totalVehicles: 0,
    totalTrips: 0,
    totalBookings: 0,
    passengersChange: AnalyticsComparison(current: 0, previous: 0),
    driversChange: AnalyticsComparison(current: 0, previous: 0),
    companiesChange: AnalyticsComparison(current: 0, previous: 0),
    periodTrips: 0,
    periodBookings: 0,
    completedTrips: 0,
    cancelledTrips: 0,
    completedBookings: 0,
    cancelledBookings: 0,
    cancellationRate: 0.0,
    seatOccupancyRate: 0.0,
    averageDriverRating: 0.0,
    onlineDrivers: 0,
    activeCompanies: 0,
    pendingDocuments: 0,
    openSupportTickets: 0,
    averageTripPriceByCurrency: {},
  );
}

class TopRoute {
  final String origin;
  final String destination;
  final int tripCount;
  final int completedTrips;

  TopRoute({
    required this.origin,
    required this.destination,
    required this.tripCount,
    required this.completedTrips,
  });
}

class AnalyticsDashboardData {
  final DashboardKPIs kpis;
  final List<TopRoute> topRoutes;

  AnalyticsDashboardData({required this.kpis, required this.topRoutes});
}
