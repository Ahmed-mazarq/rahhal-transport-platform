import 'package:flutter/material.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/seat.dart';
import '../../domain/services/seat_layout_generator.dart';

/// Normalized visual coordinate configuration for a physical seat position on the design canvas
class SeatVisualPosition {
  final String seatNumber;
  final double x; // Center X (0.0 to 1.0)
  final double y; // Center Y (0.0 to 1.0)
  final double width; // Relative Touch Width (0.0 to 1.0)
  final double height; // Relative Touch Height (0.0 to 1.0)

  const SeatVisualPosition({
    required this.seatNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Helper resolver for vehicle image assets based on passenger seat capacity
class VehicleAssetResolver {
  static String getVehicleAssetPath(int passengerSeatCount) {
    // Limits the file mapping from 3 to 14 specifically.
    int safeCount = passengerSeatCount.clamp(3, 14);
    return 'assets/images/vehicles/car_${safeCount}_seats.png';
  }

  static double getAspectRatio(int passengerSeatCount) {
    // The generated photorealistic vehicle images are 1:1 square.
    // Returning 1.0 ensures the overlay coordinates map EXACTLY to the physical image pixels
    // without BoxFit.contain introducing any padding or letterboxing.
    return 1.0;
  }
}

/// Precise physical seat coordinate maps normalized to the vehicle design canvas for capacities 3 to 14
class VehicleSeatCoordinateMap {
  static List<SeatVisualPosition> getPositions(int passengerSeatCount) {
    switch (passengerSeatCount) {
      case 3:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.35,
            y: 0.38,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.65,
            y: 0.38,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.35,
            y: 0.69,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.65,
            y: 0.69,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 4:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.36,
            y: 0.37,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.64,
            y: 0.37,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.32,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.68,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 5:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.37,
            y: 0.33,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.63,
            y: 0.33,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.28,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.43,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.57,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.72,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 6:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.39,
            y: 0.32,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.61,
            y: 0.32,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.31,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.69,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.39,
            y: 0.74,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.61,
            y: 0.74,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 7:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.38,
            y: 0.32,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.62,
            y: 0.32,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.37,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.63,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.37,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.5,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.63,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 8:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.31,
            y: 0.25,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.69,
            y: 0.25,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.3,
            y: 0.4,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.7,
            y: 0.4,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.25,
            y: 0.58,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.5,
            y: 0.58,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.75,
            y: 0.58,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.25,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.5,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.75,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 9:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.34,
            y: 0.29,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.66,
            y: 0.29,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.34,
            y: 0.47,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.47,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.66,
            y: 0.47,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.34,
            y: 0.64,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.5,
            y: 0.64,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.66,
            y: 0.64,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.34,
            y: 0.82,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.66,
            y: 0.82,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 10:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.31,
            y: 0.24,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.69,
            y: 0.24,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.31,
            y: 0.38,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.69,
            y: 0.38,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.26,
            y: 0.54,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.5,
            y: 0.54,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.74,
            y: 0.54,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.2,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.4,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.6,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '10',
            x: 0.8,
            y: 0.73,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 11:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.41,
            y: 0.26,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.59,
            y: 0.26,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.41,
            y: 0.45,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.45,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.59,
            y: 0.45,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.41,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.5,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.59,
            y: 0.61,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.36,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.45,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '10',
            x: 0.54,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '11',
            x: 0.63,
            y: 0.78,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 12:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.39,
            y: 0.28,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.61,
            y: 0.28,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.35,
            y: 0.48,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.48,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.65,
            y: 0.48,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.3,
            y: 0.65,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.43,
            y: 0.65,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.57,
            y: 0.65,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.7,
            y: 0.65,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.3,
            y: 0.82,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '10',
            x: 0.43,
            y: 0.82,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '11',
            x: 0.57,
            y: 0.82,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '12',
            x: 0.7,
            y: 0.82,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 13:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.35,
            y: 0.18,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.65,
            y: 0.18,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.31,
            y: 0.35,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.35,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.69,
            y: 0.35,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.31,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.5,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.69,
            y: 0.52,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.31,
            y: 0.69,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.5,
            y: 0.69,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '10',
            x: 0.69,
            y: 0.69,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '11',
            x: 0.31,
            y: 0.86,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '12',
            x: 0.5,
            y: 0.86,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '13',
            x: 0.69,
            y: 0.86,
            width: 0.12,
            height: 0.12,
          ),
        ];

      case 14:
        return const [
          SeatVisualPosition(
            seatNumber: '0',
            x: 0.3,
            y: 0.18,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '1',
            x: 0.7,
            y: 0.18,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '2',
            x: 0.25,
            y: 0.34,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '3',
            x: 0.5,
            y: 0.34,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '4',
            x: 0.75,
            y: 0.34,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '5',
            x: 0.25,
            y: 0.5,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '6',
            x: 0.5,
            y: 0.5,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '7',
            x: 0.75,
            y: 0.5,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '8',
            x: 0.25,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '9',
            x: 0.42,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '10',
            x: 0.58,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '11',
            x: 0.75,
            y: 0.67,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '12',
            x: 0.25,
            y: 0.83,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '13',
            x: 0.42,
            y: 0.83,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '14',
            x: 0.58,
            y: 0.83,
            width: 0.12,
            height: 0.12,
          ),
          SeatVisualPosition(
            seatNumber: '15',
            x: 0.75,
            y: 0.83,
            width: 0.12,
            height: 0.12,
          ),
        ];

      default:
        return getPositions(6);
    }
  }
}

class VehicleSeatMap extends StatelessWidget {
  final Trip trip;
  final Set<String> reservedSeatNumbers;
  final Set<String> selectedSeatNumbers;
  final bool isConfirmed;
  final Function(String) onSeatSelected;
  final bool isDriverViewer;

  const VehicleSeatMap({
    super.key,
    required this.trip,
    required this.reservedSeatNumbers,
    required this.selectedSeatNumbers,
    this.isConfirmed = false,
    required this.onSeatSelected,
    this.isDriverViewer = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Seat> actualLayout = List.from(trip.seatLayout);

    // Dynamic layout generator fallback if trip.seatLayout is empty
    if (actualLayout.isEmpty) {
      final generatedLayout = SeatLayoutGenerator.generateLayout(
        trip.totalSeats,
      );
      for (int rowIdx = 0; rowIdx < generatedLayout.length; rowIdx++) {
        for (
          int colIdx = 0;
          colIdx < generatedLayout[rowIdx].length;
          colIdx++
        ) {
          final seatNum = generatedLayout[rowIdx][colIdx];
          actualLayout.add(
            Seat(
              id: 'generated_s_$seatNum',
              number: seatNum.toString(),
              status: seatNum == 0 ? 'driver' : 'available',
              row: rowIdx,
              column: colIdx,
            ),
          );
        }
      }
    }

    // Determine passenger seat count (excluding driver 0)
    final int passengerCount = actualLayout
        .where((s) => s.number != '0' && s.status != 'driver')
        .length;
    final int targetCapacity = passengerCount > 0
        ? passengerCount
        : trip.totalSeats;

    final String assetPath = VehicleAssetResolver.getVehicleAssetPath(
      targetCapacity,
    );
    final double aspectRatio = VehicleAssetResolver.getAspectRatio(
      targetCapacity,
    );
    final List<SeatVisualPosition> positions =
        VehicleSeatCoordinateMap.getPositions(targetCapacity);

    return Container(
      color: Colors.white, // Enforce clean pure white background #FFFFFF
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLegend(),
          const SizedBox(height: 12),
          Center(
            child: Directionality(
              textDirection: TextDirection
                  .ltr, // Preserve physical top-down vehicle geometry
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Occupy ~90%–94% of mobile screen width for high legibility
                  final double maxWidth = constraints.maxWidth;
                  final double vehicleWidth = maxWidth > 420
                      ? 380.0
                      : maxWidth * 0.92;
                  final double vehicleHeight = vehicleWidth / aspectRatio;

                  return SizedBox(
                    width: vehicleWidth,
                    height: vehicleHeight,
                    child: Stack(
                      children: [
                        // DEDICATED REALISTIC TOP-DOWN CAR CABIN ASSET (PURE WHITE BG)
                        Positioned.fill(
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // ABSOLUTELY NO SILENT FALLBACK TO OTHER CAPACITIES
                              debugPrint(
                                'ERROR: Missing vehicle asset at $assetPath',
                              );
                              return Container(
                                color: Colors.white,
                                alignment: Alignment.center,
                                child: Text(
                                  'Missing vehicle asset: $assetPath',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // TRANSPARENT INTERACTION LAYER & COMPACT SEAT NUMBERS (ZERO RECTANGULAR OUTLINES)
                        ...positions.map((pos) {
                          final String seatNum = pos.seatNumber;
                          final isDriver = seatNum == '0';
                          final isReserved = reservedSeatNumbers.contains(
                            seatNum,
                          );
                          final isSelected = selectedSeatNumbers.contains(
                            seatNum,
                          );

                          // Calculate normalized seat center coordinates
                          final double left =
                              (pos.x - pos.width / 2) * vehicleWidth;
                          final double top =
                              (pos.y - pos.height / 2) * vehicleHeight;
                          final double seatW = pos.width * vehicleWidth;
                          final double seatH = pos.height * vehicleHeight;

                          return Positioned(
                            left: left,
                            top: top,
                            width: seatW,
                            height: seatH,
                            child: _TransparentSeatTouchLayer(
                              seatNumber: seatNum,
                              isDriver: isDriver,
                              isReserved: isReserved,
                              isSelected: isSelected,
                              isConfirmed: isConfirmed,
                              onTap: () {
                                if (isDriver ||
                                    (isReserved && !isDriverViewer)) {
                                  if (isReserved && !isDriverViewer) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'هذا المقعد محجوز بالكامل.',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                onSeatSelected(seatNum);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _LegendItem(color: Color(0xFF4CAF50), label: 'متاح'),
          _LegendItem(color: Color(0xFFE53935), label: 'محجوز'),
          _LegendItem(color: Color(0xFFF5A623), label: 'مقعدك'),
          _LegendItem(color: Color(0xFF263238), label: 'السائق'),
        ],
      ),
    );
  }
}

/// Fully transparent touch layer overlaying the physical seat cushion.
/// ABSOLUTELY ZERO VISIBLE RECTANGULAR BORDERS OR OUTLINES.
/// Displays only a small, compact, integrated seat number badge directly on the physical seat cushion!
class _TransparentSeatTouchLayer extends StatelessWidget {
  final String seatNumber;
  final bool isDriver;
  final bool isReserved;
  final bool isSelected;
  final bool isConfirmed;
  final VoidCallback? onTap;

  const _TransparentSeatTouchLayer({
    required this.seatNumber,
    required this.isDriver,
    required this.isReserved,
    required this.isSelected,
    required this.isConfirmed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Center(
        child: isDriver
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF263238).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_motorsports,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'السائق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isReserved
                          ? const Color(0xFFE53935)
                          : isSelected
                          ? const Color(0xFFF5A623)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isReserved || isSelected
                            ? Colors.transparent
                            : const Color(0xFF1B5E20),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      seatNumber,
                      style: TextStyle(
                        color: isReserved || isSelected
                            ? Colors.white
                            : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  if (isSelected && isConfirmed)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
