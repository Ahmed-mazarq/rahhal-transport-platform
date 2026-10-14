import 'package:flutter/material.dart';
import '../../features/trips/domain/services/seat_layout_generator.dart';

class InteractiveSeatMap extends StatelessWidget {
  final Map<int, int>
  seatMap; // 0=Available, 1=Occupied, 2=FemaleOnly, 3=VIP, 4=PendingVerification
  final List<int> selectedSeats;
  final Function(int) onSeatTapped;
  final int totalSeats;
  final bool isDriverViewer;

  const InteractiveSeatMap({
    super.key,
    required this.seatMap,
    required this.selectedSeats,
    required this.onSeatTapped,
    this.totalSeats = 4, // Default to a standard car layout
    this.isDriverViewer = false,
  });

  @override
  Widget build(BuildContext context) {
    final layout = SeatLayoutGenerator.generateLayout(totalSeats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegend(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: layout.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((seatNum) {
                    if (seatNum == -1) {
                      return const SizedBox(width: 48, height: 48); // Aisle
                    }
                    return _buildSeat(
                      context,
                      seatNum,
                      isDriverModel: seatNum == 0,
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(Colors.white, 'متاح', true),
        _legendItem(const Color(0xFF0B1F3A), 'محدد', false),
        _legendItem(Colors.grey.shade400, 'محجوز', false),
        _legendItem(Colors.orange.shade400, 'بانتظار التأكيد', false),
        _legendItem(Colors.pink.shade300, 'للنساء', false),
        _legendItem(const Color(0xFFF5A623), 'VIP', false),
      ],
    );
  }

  Widget _legendItem(Color color, String label, bool isAvailable) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isAvailable
                ? Border.all(color: Colors.grey.shade400)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSeat(
    BuildContext context,
    int seatNumber, {
    bool isDriverModel = false,
  }) {
    final currentStatus = isDriverModel ? 1 : (seatMap[seatNumber] ?? 0);
    final isSelected = selectedSeats.contains(seatNumber);

    Color seatColor;
    Color borderColor = Colors.transparent;
    Widget? icon;

    if (isDriverModel) {
      seatColor = Colors.grey.shade800;
      icon = const Icon(Icons.drive_eta, color: Colors.white, size: 24);
    } else if (isSelected) {
      seatColor = const Color(0xFF0B1F3A);
      icon = Text(
        seatNumber.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else if (currentStatus == 1) {
      seatColor = Colors.grey.shade400;
      icon = const Icon(Icons.close, color: Colors.white, size: 20);
    } else if (currentStatus == 2) {
      seatColor = Colors.pink.shade300;
      icon = const Icon(Icons.female, color: Colors.white, size: 20);
    } else if (currentStatus == 3) {
      seatColor = const Color(0xFFF5A623);
      icon = const Icon(Icons.star, color: Colors.white, size: 20);
    } else if (currentStatus == 4) {
      seatColor = Colors.orange.shade400;
      icon = const Icon(Icons.hourglass_empty, color: Colors.white, size: 20);
    } else {
      seatColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.white;
      borderColor = Colors.grey.shade400;
      icon = Text(
        seatNumber.toString(),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    return GestureDetector(
      onTap:
          isDriverModel ||
              currentStatus == 4 ||
              (currentStatus == 1 && !isDriverViewer)
          ? null
          : () => onSeatTapped(seatNumber),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: AnimatedContainer(
          key: ValueKey<String>(
            'seat_${seatNumber}_${isSelected}_$currentStatus',
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0B1F3A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
