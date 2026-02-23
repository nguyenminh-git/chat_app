import 'package:chatapp/services/friend_service.dart';
import 'package:flutter/material.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yêu cầu kết bạn"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _friendService.getFriendRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Lỗi"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có yêu cầu kết bạn nào"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data =
                  doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['senderEmail']),
                  subtitle: const Text("Đã gửi cho bạn một lời mời kết bạn"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _friendService.acceptFriendRequest(
                          doc.id,
                          data['senderUid'],
                          data['senderEmail'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _friendService.rejectFriendRequest(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
