import 'package:chatapp/components/chat_bubble.dart';
import 'package:chatapp/components/my_text_field.dart';
import 'package:chatapp/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isSendingImage = false;

  // cho focus của textfield
  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // thêm listener cho focus node
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // tạo độ trễ để bàn phím có thời gian hiển thị
        // sau đó lượng không gian còn lại sẽ được tính toán,
        // sau đó cuộn xuống
        Future.delayed(
          const Duration(milliseconds: 500),
          () => scrollDown(),
        );
      }
    });

    // đợi một chút để listview được tạo, sau đó cuộn xuống dưới cùng
    Future.delayed(
      const Duration(milliseconds: 500),
      () => scrollDown(),
    );
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // bộ điều khiển cuộn (scroll controller)
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  // gửi tin nhắn
  void sendMessage() async {
    // nếu có nội dung trong textfield
    if (_messageController.text.isNotEmpty) {
      // gửi tin nhắn
      await _chatService.sendMessage(widget.receiverID, _messageController.text);

      // xóa text controller
      _messageController.clear();
    }

    scrollDown();
  }

  // gửi hình ảnh
  Future<void> sendImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isSendingImage = true;
      });
      try {
        Uint8List imageBytes = await pickedFile.readAsBytes();
        await _chatService.sendImage(widget.receiverID, imageBytes);
        scrollDown();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi gửi ảnh: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSendingImage = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        children: [
          // hiển thị tất cả tin nhắn
          Expanded(
            child: _buildMessageList(),
          ),

          // đầu vào người dùng
          _buildUserInput(),
        ],
      ),
    );
  }

  // tạo danh sách tin nhắn
  Widget _buildMessageList() {
    String senderID = _auth.currentUser!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        // lỗi
        if (snapshot.hasError) {
          return const Text("Error");
        }

        // đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }

        // trả về list view
        return ListView(
          controller: _scrollController,
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  // tạo mục tin nhắn
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // là người dùng hiện tại
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;

    // căn phải nếu người gửi là người dùng hiện tại, ngược lại căn trái
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
            type: data["type"] ?? 'text', // lấy loại tin nhắn
          ),
        ],
      ),
    );
  }

  // tạo đầu vào tin nhắn
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        children: [
          // nút chọn ảnh
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: IconButton(
              onPressed: sendImage,
              icon: const Icon(
                Icons.image,
                color: Colors.grey,
              ),
            ),
          ),

          // textfield nên chiếm phần lớn không gian
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Type a message",
              obscureText: false,
              focusNode: myFocusNode,
            ),
          ),

          // nút gửi
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 25),
            child: _isSendingImage
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
