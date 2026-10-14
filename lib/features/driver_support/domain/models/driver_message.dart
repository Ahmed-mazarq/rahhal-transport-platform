import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class DriverMessage extends Equatable {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderRole; // 'driver' or 'admin'
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final bool isDelivered;

  // Attachments
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? mimeType;
  final String? thumbnail;
  final int? duration;

  const DriverMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.senderRole = 'driver',
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.isDelivered = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.mimeType,
    this.thumbnail,
    this.duration,
  });

  factory DriverMessage.fromJson(Map<String, dynamic> json, String id) {
    return DriverMessage(
      messageId: id,
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderRole:
          json['senderRole'] ??
          json['senderType'] ??
          'driver', // fallback to senderType for old data
      message:
          json['message'] ??
          json['text'] ??
          '', // fallback to text for old data
      createdAt: DateParser.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      attachmentUrl: json['attachmentUrl'],
      attachmentName: json['attachmentName'],
      attachmentSize: json['attachmentSize'],
      mimeType: json['mimeType'],
      thumbnail: json['thumbnail'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDelivered': isDelivered,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentName != null) 'attachmentName': attachmentName,
      if (attachmentSize != null) 'attachmentSize': attachmentSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (duration != null) 'duration': duration,
    };
  }

  @override
  List<Object?> get props => [
    messageId,
    conversationId,
    senderId,
    senderRole,
    message,
    createdAt,
    isRead,
    isDelivered,
    attachmentUrl,
    attachmentName,
    attachmentSize,
    mimeType,
    thumbnail,
    duration,
  ];
}
