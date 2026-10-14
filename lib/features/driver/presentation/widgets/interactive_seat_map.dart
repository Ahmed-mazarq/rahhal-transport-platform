import 'package:flutter/material.dart';
import '../../../trips/domain/models/seat.dart';
import '../../../../core/widgets/interactive_seat_map.dart' as core;

class InteractiveSeatMap extends StatelessWidget {
  final List<Seat> seats;
  final Function(Seat) onSeatTap;
  final int maxColumns;

  const InteractiveSeatMap({
    super.key,
    required this.seats,
    required this.onSeatTap,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد تخطيط للمقاعد',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    final Map<int, int> seatMap = {};
    for (var seat in seats) {
      int sNum = int.tryParse(seat.number) ?? 0;
      if (sNum > 0) {
        if (seat.isVip) {
          seatMap[sNum] = 3;
        } else if (seat.isWomenOnly) {
          seatMap[sNum] = 2;
        } else if (seat.status == 'booked' || seat.status == 'blocked') {
          seatMap[sNum] = 1;
        } else if (seat.status == 'temporarily_reserved') {
          seatMap[sNum] = 4;
        } else {
          seatMap[sNum] = 0;
        }
      }
    }

    return core.InteractiveSeatMap(
      totalSeats: seats.length,
      seatMap: seatMap,
      selectedSeats: const [],
      onSeatTapped: (seatNum) {
        final seat = seats.firstWhere(
          (s) => s.number == seatNum.toString(),
          orElse: () =>
              Seat(id: '', number: seatNum.toString(), row: 0, column: 0),
        );
        onSeatTap(seat);
      },
    );
  }
}
