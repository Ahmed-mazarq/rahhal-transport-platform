class SeatLayoutGenerator {
  /// Generates a structured seat layout for passenger seat counts 3 through 14.
  /// `0` = Driver Seat
  /// `1` to `N` = Passenger Seats
  static List<List<int>> generateLayout(int passengerSeats) {
    if (passengerSeats == 3) {
      return [
        [0, 1],
        [3, 2],
      ];
    }
    if (passengerSeats == 4) {
      return [
        [0, 1],
        [4, 3, 2],
      ];
    }
    if (passengerSeats == 5) {
      return [
        [0, 1],
        [4, 3, 2],
        [5],
      ];
    }
    if (passengerSeats == 6) {
      return [
        [0, 1],
        [4, 3, 2],
        [6, 5],
      ];
    }
    if (passengerSeats == 7) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
      ];
    }
    if (passengerSeats == 8) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [8],
      ];
    }
    if (passengerSeats == 9) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [9, 8],
      ];
    }
    if (passengerSeats == 10) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [10, 9, 8],
      ];
    }
    if (passengerSeats == 11) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [10, 9, 8],
        [11],
      ];
    }
    if (passengerSeats == 12) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [10, 9, 8],
        [12, 11],
      ];
    }
    if (passengerSeats == 13) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [10, 9, 8],
        [13, 12, 11],
      ];
    }
    if (passengerSeats == 14) {
      return [
        [0, 1],
        [4, 3, 2],
        [7, 6, 5],
        [10, 9, 8],
        [14, 13, 12, 11],
      ];
    }

    // Dynamic Safe Fallback for custom passenger counts > 14 or < 3
    List<List<int>> layout = [
      [0, 1],
    ];
    int currentSeat = 2;
    while (currentSeat <= passengerSeats) {
      int remaining = passengerSeats - currentSeat + 1;
      int seatsInRow = remaining >= 3 ? 3 : remaining;
      List<int> row = [];
      for (int i = 0; i < seatsInRow; i++) {
        row.add(currentSeat++);
      }
      layout.add(row.reversed.toList());
    }
    return layout;
  }
}
