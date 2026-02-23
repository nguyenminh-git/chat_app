import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String type; // Mặc định là text

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.type = 'text',
  });

  @override
  Widget build(BuildContext context) {
    bool isImage = type == 'image';

    return Container(
      decoration: BoxDecoration(
        color: isImage ? Colors.transparent : (isCurrentUser ? Colors.green : Colors.grey.shade500),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: isImage ? EdgeInsets.zero : const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
      child: isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message, // URL tải từ internet
                width: 200, // Chiều rộng tối đa của ảnh
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            )
          : Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
    );
  }
}
