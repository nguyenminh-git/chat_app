import 'package:chatapp/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tìm kiếm người dùng"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Nhập email để tìm kiếm...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search),
                  ),
                  onPressed: () {
                    setState(() {}); // Build lại để chạy FutureBuilder
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _searchController.text.isEmpty
                  ? const Stream.empty()
                  : _friendService.searchUserByEmail(_searchController.text.trim()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  if (_searchController.text.isNotEmpty) {
                    return const Center(child: Text("Không tìm thấy người dùng"));
                  }
                  return const Center(child: Text("Nhập email để tìm kiếm"));
                }

                var currentUserEmail = _auth.currentUser?.email;

                // Lọc bỏ người dùng hiện tại khỏi kết quả (lọc phía client)
                var users = snapshot.data!.docs.where((doc) {
                  var userData = doc.data() as Map<String, dynamic>;
                  return userData['email'] != currentUserEmail;
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("Không tìm thấy người dùng"));
                }

                return ListView(
                  children: users.map((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: ListTile(
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(userData['email']),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () async {
                            try {
                              await _friendService
                                  .sendFriendRequest(userData['email']);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Đã gửi yêu cầu kết bạn!")));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())));
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
