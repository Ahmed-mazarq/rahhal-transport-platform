import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/trip.dart';
import '../../../driver/domain/models/driver_payment_method.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/rahhal_app_bar.dart';
import '../../../../core/utils/currency_formatter.dart';

final paymentMethodsProvider =
    FutureProvider.family<List<DriverPaymentMethod>, String>((
      ref,
      driverId,
    ) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('driver_payment_methods')
          .where('driverId', isEqualTo: driverId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => DriverPaymentMethod.fromJson(doc.data()..['id'] = doc.id),
          )
          .toList();
    });

class BookingPaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingPaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  Booking? _booking;
  Trip? _trip;
  bool _isLoading = true;
  String? _selectedPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final booking = await tripRepo.getBooking(widget.bookingId);
      if (booking == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final trip = await tripRepo.getTrip(booking.tripId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _trip = trip;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ $label بنجاح.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_booking == null) {
      return const Scaffold(
        appBar: RahhalAppBar(
          titleText: 'الدفع',
        ),
        body: Center(
          child: Text('الحجز غير موجود', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }

    final booking = _booking!;

    return Scaffold(
      appBar: const RahhalAppBar(
        titleText: 'دفع مبلغ التأكيد',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amounts Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'مبلغ تأكيد الحجز',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrencyAmount(booking.depositAmount, booking.currency),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5A623),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المتبقي بعد التأكيد:',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                      ),
                      Text(
                        formatCurrencyAmount(booking.remainingAmount, booking.currency),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'طرق الدفع المتاحة للسائق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Payment Methods
            Consumer(
              builder: (context, ref, child) {
                final methodsAsync = ref.watch(
                  paymentMethodsProvider(booking.driverId),
                );

                return methodsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(
                    child: Text(
                      'تعذر تحميل وسائل الدفع.',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  data: (allMethods) {
                    final tripMethodIds = _trip?.paymentMethodIds ?? [];
                    final methods = tripMethodIds.isNotEmpty
                        ? allMethods
                              .where((m) => tripMethodIds.contains(m.id))
                              .toList()
                        : allMethods;

                    if (methods.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            tripMethodIds.isEmpty
                                ? 'لم يقم السائق بتحديد حسابات دفع لهذه الرحلة'
                                : 'لا توجد حالياً حسابات دفع متاحة لهذه الرحلة.',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    }

                    if (_selectedPaymentMethodId == null &&
                        methods.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedPaymentMethodId = methods.first.id;
                          });
                        }
                      });
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: methods.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final method = methods[index];
                        final isBank = method.type == 'bank';
                        final isSelected =
                            _selectedPaymentMethodId == method.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethodId = method.id;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isSelected
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFF1A1A1A))
                                  : (isSelected
                                        ? Colors.blue.withValues(alpha: 0.05)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: method.id,
                                      groupValue: _selectedPaymentMethodId,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPaymentMethodId = value;
                                        });
                                      },
                                    ),
                                    Icon(
                                      isBank
                                          ? Icons.account_balance
                                          : Icons.account_balance_wallet,
                                      color: const Color(0xFF0B1F3A),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isBank ? 'تحويل بنكي' : 'محفظة إلكترونية',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      method.providerName,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                if (method.accountHolderName.isNotEmpty) ...[
                                  _buildDetailRow(
                                    'اسم المستفيد:',
                                    method.accountHolderName,
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isBank
                                              ? 'رقم الحساب:'
                                              : 'رقم المحفظة:',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          method.accountNumber,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _copyToClipboard(
                                        method.accountNumber,
                                        isBank ? 'رقم الحساب' : 'رقم المحفظة',
                                      ),
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text(
                                        'نسخ',
                                        style: TextStyle(fontFamily: 'Cairo'),
                                      ),
                                    ),
                                  ],
                                ),

                                if (method.iban.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'IBAN:',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            method.iban,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _copyToClipboard(
                                          method.iban,
                                          'الآيبان',
                                        ),
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: const Text(
                                          'نسخ',
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _selectedPaymentMethodId == null
                  ? null
                  : () {
                      context.push(
                        '/booking-proof/${booking.id}?paymentMethodId=$_selectedPaymentMethodId',
                      );
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF0B1F3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text(
                'أتممت التحويل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
