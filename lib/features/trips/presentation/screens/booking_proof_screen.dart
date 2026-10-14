import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/booking.dart';

class BookingProofScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String? paymentMethodId;

  const BookingProofScreen({
    super.key,
    required this.bookingId,
    this.paymentMethodId,
  });

  @override
  ConsumerState<BookingProofScreen> createState() => _BookingProofScreenState();
}

class _BookingProofScreenState extends ConsumerState<BookingProofScreen> {
  Booking? _booking;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _amountController = TextEditingController();

  Uint8List? _receiptImageBytes;
  XFile? _receiptFile;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _senderNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final booking = await tripRepo.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          if (booking != null) {
            _amountController.text = booking.depositAmount.toString();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        setState(() {
          _receiptFile = pickedFile;
          _receiptImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _submitProof() async {
    if (_isSubmitting) return; // Prevent double submission
    if (!_formKey.currentState!.validate()) return;

    if (_receiptImageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى رفع صورة الإيصال.')));
      return;
    }

    final enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (enteredAmount != _booking!.depositAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'مبلغ التحويل يجب أن يكون ${_booking!.depositAmount} ريال.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    debugPrint('[PAYMENT_PROOF] submit started');
    debugPrint('[PAYMENT_PROOF] image validation passed');

    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final storage = ref.read(paymentProofStorageProvider);

      debugPrint('[PAYMENT_PROOF] uploading image to development storage');
      final downloadUrl = await storage.uploadPaymentProof(
        widget.bookingId,
        _receiptFile!,
      );
      debugPrint('[PAYMENT_PROOF] URL received: $downloadUrl');

      // Submit proof via repository
      debugPrint('[PAYMENT_PROOF] updating booking');
      await tripRepo
          .submitPaymentProof(
            widget.bookingId,
            downloadUrl,
            _referenceController.text.trim(),
            _senderNameController.text.trim(),
            enteredAmount,
            widget.paymentMethodId,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () =>
                throw TimeoutException('Firestore update timed out'),
          );

      debugPrint('[PAYMENT_PROOF] submission completed');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Navigate to booking details screen to show real-time status
      context.pushReplacement('/booking-details/${widget.bookingId}');
    } catch (e) {
      debugPrint('[PAYMENT_PROOF] FAILURE: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      String errorMsg = 'تعذر رفع إثبات التحويل.';
      if (e is TimeoutException ||
          e.toString().toLowerCase().contains('timeout')) {
        errorMsg =
            'انتهت مهلة الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.';
      } else if (e.toString().toLowerCase().contains('permission-denied') ||
          e.toString().toLowerCase().contains('unauthorized') ||
          e.toString().toLowerCase().contains('rls')) {
        errorMsg = 'لا تملك صلاحية رفع الإيصال.';
      } else if (e.toString().toLowerCase().contains('network')) {
        errorMsg = 'حدث خطأ في الشبكة، يرجى التحقق من اتصالك.';
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'إثبات الدفع',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        body: const Center(
          child: Text('الحجز غير موجود', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إثبات الدفع', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'يرجى إرفاق تفاصيل عملية التحويل',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Image Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _receiptImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _receiptImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'إرفاق صورة الإيصال (إلزامي)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Form Fields
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'رقم العملية / المرجع',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'رقم العملية مطلوب.'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _senderNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المرسل',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اسم المرسل مطلوب.'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
                suffixText: 'ريال',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'المبلغ مطلوب.';
                }
                final num = double.tryParse(value);
                if (num == null || num <= 0) return 'يرجى إدخال مبلغ صحيح.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: DateTime.now().toString().split('.')[0],
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'تاريخ ووقت التحويل',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'جاري الإرسال...',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'تأكيد الإرسال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
