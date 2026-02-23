import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final String type; // 'text' hoặc 'image'
  final Timestamp timestamp;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    this.type = 'text', // Mặc định là text
    required this.timestamp,
  });

  // Chuyển đổi thành map để lưu vào firestore
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
