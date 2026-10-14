import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking extends Equatable {
  final String id;
  final String tripId;
  final String passengerId;
  final String driverId;
  final double seatCount;
  final String
  status; // pending, confirmed, completed, cancelled, rejected, awaiting_payment, awaiting_driver_verification, payment_not_received, expired, support_review, cancelled_by_passenger, cancelled_by_driver
  final DateTime bookingTime;

  // Expanded fields for comprehensive booking details
  final String seatNumber; // Can be comma separated or JSON array if multiple
  final List<String> seatNumbers; // Canonical new field for selected seats

  final String
  paymentStatus; // pending, paid, unpaid, refunded, awaiting_payment, deposit_verified, payment_not_received
  final String qrCode;
  final String departureCity;
  final String arrivalCity;
  final DateTime travelDate;
  final double price; // The total trip price equivalent or base price
  final String currency; // Added for proper multi-currency support
  final String driverName;
  final String name; // Used interchangeably with passengerName
  final String vehiclePlate;

  // New fields for Driver Workflow
  final String
  attendanceStatus; // none, present, absent, late, cancelled, no_show
  final String pickupPoint;
  final String dropoffPoint;
  final String notes;

  // Added fields for deposit payment workflow
  final double depositAmount;
  final double remainingAmount;
  final String paymentProofUrl;
  final String transactionReference;
  final String senderName;
  final double transferAmount;
  final DateTime? transferSubmittedAt;
  final DateTime? paymentDeadline;
  final DateTime? paymentVerifiedAt;
  final String paymentVerifiedBy;
  final bool depositConfirmed;
  final String paymentRejectionReason;
  final DateTime? paymentRejectedAt;
  final String paymentRejectedBy;
  final String bookingNumber;
  final String supportReportId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentMethodId;
  final String bookingType; // 'passenger' or 'driver_manual'
  final bool isRated;
  final double? rating;

  const Booking({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.driverId,
    required this.seatCount,
    required this.status,
    required this.bookingTime,
    this.seatNumber = '1',
    this.seatNumbers = const [],
    this.paymentStatus = 'pending',
    this.qrCode = '',
    this.departureCity = '',
    this.arrivalCity = '',
    required this.travelDate,
    this.price = 0.0,
    this.currency = '',
    this.driverName = 'كابتن رحال',
    this.name = '',
    this.vehiclePlate = '',
    this.attendanceStatus = 'none',
    this.pickupPoint = '',
    this.dropoffPoint = '',
    this.notes = '',
    this.depositAmount = 0.0,
    this.remainingAmount = 0.0,
    this.paymentProofUrl = '',
    this.transactionReference = '',
    this.senderName = '',
    this.transferAmount = 0.0,
    this.transferSubmittedAt,
    this.paymentDeadline,
    this.paymentVerifiedAt,
    this.paymentVerifiedBy = '',
    this.depositConfirmed = false,
    this.paymentRejectionReason = '',
    this.paymentRejectedAt,
    this.paymentRejectedBy = '',
    this.bookingNumber = '',
    this.supportReportId = '',
    this.createdAt,
    this.updatedAt,
    this.paymentMethodId,
    this.bookingType = 'passenger',
    this.isRated = false,
    this.rating,
  });

  Booking copyWith({
    String? id,
    String? tripId,
    String? passengerId,
    String? driverId,
    double? seatCount,
    String? status,
    DateTime? bookingTime,
    String? seatNumber,
    List<String>? seatNumbers,
    String? paymentStatus,
    String? qrCode,
    String? departureCity,
    String? arrivalCity,
    DateTime? travelDate,
    double? price,
    String? currency,
    String? driverName,
    String? name,
    String? vehiclePlate,
    String? attendanceStatus,
    String? pickupPoint,
    String? dropoffPoint,
    String? notes,
    double? depositAmount,
    double? remainingAmount,
    String? paymentProofUrl,
    String? transactionReference,
    String? senderName,
    double? transferAmount,
    DateTime? transferSubmittedAt,
    DateTime? paymentDeadline,
    DateTime? paymentVerifiedAt,
    String? paymentVerifiedBy,
    bool? depositConfirmed,
    String? paymentRejectionReason,
    DateTime? paymentRejectedAt,
    String? paymentRejectedBy,
    String? bookingNumber,
    String? supportReportId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethodId,
    String? bookingType,
    bool? isRated,
    double? rating,
  }) {
    return Booking(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      seatCount: seatCount ?? this.seatCount,
      status: status ?? this.status,
      bookingTime: bookingTime ?? this.bookingTime,
      seatNumber: seatNumber ?? this.seatNumber,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      qrCode: qrCode ?? this.qrCode,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      travelDate: travelDate ?? this.travelDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      driverName: driverName ?? this.driverName,
      name: name ?? this.name,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      dropoffPoint: dropoffPoint ?? this.dropoffPoint,
      notes: notes ?? this.notes,
      depositAmount: depositAmount ?? this.depositAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      transactionReference: transactionReference ?? this.transactionReference,
      senderName: senderName ?? this.senderName,
      transferAmount: transferAmount ?? this.transferAmount,
      transferSubmittedAt: transferSubmittedAt ?? this.transferSubmittedAt,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
      paymentVerifiedBy: paymentVerifiedBy ?? this.paymentVerifiedBy,
      depositConfirmed: depositConfirmed ?? this.depositConfirmed,
      paymentRejectionReason:
          paymentRejectionReason ?? this.paymentRejectionReason,
      paymentRejectedAt: paymentRejectedAt ?? this.paymentRejectedAt,
      paymentRejectedBy: paymentRejectedBy ?? this.paymentRejectedBy,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      supportReportId: supportReportId ?? this.supportReportId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      bookingType: bookingType ?? this.bookingType,
      isRated: isRated ?? this.isRated,
      rating: rating ?? this.rating,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      passengerId: json['passengerId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      seatCount: (json['seatCount'] as num?)?.toDouble() ?? 1.0,
      status: json['status'] as String? ?? 'pending',
      bookingTime: DateParser.parse(json['bookingTime']),
      seatNumber: json['seatNumber']?.toString() ?? '1',
      seatNumbers: json['seatNumbers'] != null
          ? List<String>.from(json['seatNumbers'])
          : (json['seatNumber']?.toString() ?? '1')
                .split(',')
                .map((s) => s.trim())
                .toList(),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      qrCode: json['qrCode'] as String? ?? '',
      departureCity: json['departureCity'] as String? ?? '',
      arrivalCity: json['arrivalCity'] as String? ?? '',
      travelDate: DateParser.parse(json['travelDate']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '',
      driverName: json['driverName'] as String? ?? 'كابتن رحال',
      name: json['name'] ?? json['passengerName'] ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? '',
      attendanceStatus: json['attendanceStatus'] as String? ?? 'none',
      pickupPoint: json['pickupPoint'] as String? ?? '',
      dropoffPoint: json['dropoffPoint'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentProofUrl: json['paymentProofUrl'] as String? ?? '',
      transactionReference: json['transactionReference'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      transferAmount: (json['transferAmount'] as num?)?.toDouble() ?? 0.0,
      transferSubmittedAt: json['transferSubmittedAt'] != null
          ? DateParser.parse(json['transferSubmittedAt'])
          : null,
      paymentDeadline: json['paymentDeadline'] != null
          ? DateParser.parse(json['paymentDeadline'])
          : null,
      paymentVerifiedAt: json['paymentVerifiedAt'] != null
          ? DateParser.parse(json['paymentVerifiedAt'])
          : null,
      paymentVerifiedBy: json['paymentVerifiedBy'] as String? ?? '',
      depositConfirmed: json['depositConfirmed'] as bool? ?? false,
      paymentRejectionReason: json['paymentRejectionReason'] as String? ?? '',
      paymentRejectedAt: json['paymentRejectedAt'] != null
          ? DateParser.parse(json['paymentRejectedAt'])
          : null,
      paymentRejectedBy: json['paymentRejectedBy'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? '',
      supportReportId: json['supportReportId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateParser.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateParser.parse(json['updatedAt'])
          : null,
      paymentMethodId: json['paymentMethodId'] as String?,
      bookingType: json['bookingType'] as String? ?? 'passenger',
      isRated: json['isRated'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'passengerId': passengerId,
      'driverId': driverId,
      'seatCount': seatCount,
      'status': status,
      'bookingTime': bookingTime.toIso8601String(),
      'seatNumber': seatNumber,
      'seatNumbers': seatNumbers.isNotEmpty
          ? seatNumbers
          : seatNumber.split(',').map((s) => s.trim()).toList(),
      'paymentStatus': paymentStatus,
      'qrCode': qrCode,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'travelDate': travelDate.toIso8601String(),
      'price': price,
      'currency': currency,
      'driverName': driverName,
      'name': name,
      'vehiclePlate': vehiclePlate,
      'attendanceStatus': attendanceStatus,
      'pickupPoint': pickupPoint,
      'dropoffPoint': dropoffPoint,
      'notes': notes,
      'depositAmount': depositAmount,
      'remainingAmount': remainingAmount,
      'paymentProofUrl': paymentProofUrl,
      'transactionReference': transactionReference,
      'senderName': senderName,
      'transferAmount': transferAmount,
      if (transferSubmittedAt != null)
        'transferSubmittedAt': transferSubmittedAt!.toIso8601String(),
      if (paymentDeadline != null)
        'paymentDeadline': Timestamp.fromDate(paymentDeadline!),
      if (paymentVerifiedAt != null)
        'paymentVerifiedAt': paymentVerifiedAt!.toIso8601String(),
      'paymentVerifiedBy': paymentVerifiedBy,
      'depositConfirmed': depositConfirmed,
      'paymentRejectionReason': paymentRejectionReason,
      if (paymentRejectedAt != null)
        'paymentRejectedAt': paymentRejectedAt!.toIso8601String(),
      'paymentRejectedBy': paymentRejectedBy,
      'bookingNumber': bookingNumber,
      'supportReportId': supportReportId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      'bookingType': bookingType,
      'isRated': isRated,
      if (rating != null) 'rating': rating,
    };
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    passengerId,
    driverId,
    seatCount,
    status,
    bookingTime,
    seatNumber,
    seatNumbers,
    paymentStatus,
    qrCode,
    departureCity,
    arrivalCity,
    travelDate,
    price,
    currency,
    driverName,
    name,
    vehiclePlate,
    attendanceStatus,
    pickupPoint,
    dropoffPoint,
    notes,
    depositAmount,
    remainingAmount,
    paymentProofUrl,
    transactionReference,
    senderName,
    transferAmount,
    transferSubmittedAt,
    paymentDeadline,
    paymentVerifiedAt,
    paymentVerifiedBy,
    depositConfirmed,
    paymentRejectionReason,
    paymentRejectedAt,
    paymentRejectedBy,
    bookingNumber,
    supportReportId,
    createdAt,
    updatedAt,
    paymentMethodId,
    bookingType,
    isRated,
    rating,
  ];
}
