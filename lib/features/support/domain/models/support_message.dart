import '../../../common/utils/date_parser.dart';

class SupportMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String text;
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

  const SupportMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.text,
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

  factory SupportMessage.fromJson(Map<String, dynamic> json, String id) {
    return SupportMessage(
      messageId: id,
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? json['senderRole'] ?? '',
      text: json['text'] ?? json['message'] ?? '',
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
      'senderType': senderType,
      'text': text,
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
}
