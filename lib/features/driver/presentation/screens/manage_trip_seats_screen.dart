import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../trips/domain/models/seat.dart';
import '../../../trips/domain/services/seat_layout_generator.dart';
import '../widgets/interactive_seat_map.dart';
import '../utils/driver_tokens.dart';

class ManageTripSeatsScreen extends StatefulWidget {
  final List<Seat>? initialSeats;
  final int? vehicleSeatsCount;

  const ManageTripSeatsScreen({
    super.key,
    this.initialSeats,
    this.vehicleSeatsCount,
  });

  @override
  State<ManageTripSeatsScreen> createState() => _ManageTripSeatsScreenState();
}

class _ManageTripSeatsScreenState extends State<ManageTripSeatsScreen> {
  late List<Seat> _seats;

  @override
  void initState() {
    super.initState();
    if (widget.initialSeats != null && widget.initialSeats!.isNotEmpty) {
      _seats = List<Seat>.from(widget.initialSeats!);
    } else {
      _initializeLayout(widget.vehicleSeatsCount ?? 12);
    }
  }

  void _initializeLayout(int totalSeats) {
    _seats = [];
    final layout = SeatLayoutGenerator.generateLayout(totalSeats);
    for (int r = 0; r < layout.length; r++) {
      for (int c = 0; c < layout[r].length; c++) {
        final seatNum = layout[r][c];
        _seats.add(
          Seat(
            id: 's_$seatNum',
            number: seatNum.toString(),
            status: seatNum == 0 ? 'driver' : 'available',
            row: r,
            column: c,
          ),
        );
      }
    }
  }

  void _toggleSeatProperties(Seat seat) {
    if (seat.status == 'driver') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذا مقعد السائق ولا يمكن تعديله',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (seat.status == 'booked') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'هذا المقعد محجوز من قبل راكب. لا يمكن تعديله لحماية بيانات الحجز.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticWarning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DriverTokens.radiusCard),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSeat = _seats.firstWhere(
              (s) => s.id == seat.id,
              orElse: () => seat,
            );
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(DriverTokens.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إعدادات المقعد رقم ${currentSeat.number}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      title: const Text(
                        'حجب / تعطيل المقعد',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      subtitle: const Text(
                        'لن يتمكن الركاب من حجز هذا المقعد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Switch(
                        value: currentSeat.status == 'blocked',
                        activeColor: DriverTokens.primaryNavy,
                        onChanged: (val) {
                          setState(() {
                            final index = _seats.indexWhere(
                              (s) => s.id == seat.id,
                            );
                            if (index != -1) {
                              _seats[index] = currentSeat.copyWith(
                                status: val ? 'blocked' : 'available',
                              );
                            }
                          });
                          setModalState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        'مخصص للنساء فقط',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      trailing: Switch(
                        value: currentSeat.isWomenOnly,
                        activeColor: DriverTokens.accentGold,
                        onChanged: (val) {
                          setState(() {
                            final index = _seats.indexWhere(
                              (s) => s.id == seat.id,
                            );
                            if (index != -1) {
                              _seats[index] = currentSeat.copyWith(
                                isWomenOnly: val,
                              );
                            }
                          });
                          setModalState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        'مقعد VIP متميز',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      trailing: Switch(
                        value: currentSeat.isVip,
                        activeColor: DriverTokens.accentGold,
                        onChanged: (val) {
                          setState(() {
                            final index = _seats.indexWhere(
                              (s) => s.id == seat.id,
                            );
                            if (index != -1) {
                              _seats[index] = currentSeat.copyWith(isVip: val);
                            }
                          });
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverTokens.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DriverTokens.radiusSmall,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'تم',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تخطيط وتخصيص المقاعد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: DriverTokens.primaryNavy,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                context.pop(_seats);
              },
              child: const Text(
                'حفظ التخطيط',
                style: TextStyle(
                  color: DriverTokens.accentGold,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: DriverTokens.primaryNavy.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(DriverTokens.spaceMd),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: DriverTokens.primaryNavy),
                      SizedBox(width: DriverTokens.spaceSm),
                      Expanded(
                        child: Text(
                          'اضغط على أي مقعد لتخصيصه (حجب، مخصص للنساء، أو VIP). المقاعد المحجوزة مسبقاً محمية تلقائياً.',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceLg),
              InteractiveSeatMap(
                seats: _seats,
                onSeatTap: _toggleSeatProperties,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
