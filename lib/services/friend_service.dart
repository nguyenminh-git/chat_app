import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream danh sách bạn bè của người dùng hiện tại
  Stream<DocumentSnapshot> getFriendsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore.collection('users').doc(currentUser.uid).snapshots();
  }

  // Stream các yêu cầu kết bạn đang chờ
  Stream<QuerySnapshot> getFriendRequestsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friend_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Gửi yêu cầu kết bạn qua email
  Future<void> sendFriendRequest(String receiverEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    // 1. Tìm người dùng bằng email
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: receiverEmail)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("User with this email not found");
    }

    final receiverDoc = querySnapshot.docs.first;
    final receiverID = receiverDoc.id;

    // 2. Xác thực (Validation)
    if (receiverID == currentUser.uid) {
      throw Exception("You cannot send a friend request to yourself");
    }

    // Kiểm tra xem đã là bạn bè chưa (có thể thêm kiểm tra phía client, nhưng kiểm tra DB ở đây là tốt)
    // Để đơn giản, giả sử UI xử lý kiểm tra "đã là bạn bè", hoặc để quy tắc Firestore xử lý bảo mật.
    // Ở đây chỉ kiểm tra xem yêu cầu đã tồn tại chưa để tránh trùng lặp
    final existingRequest = await _firestore
        .collection('users')
        .doc(receiverID)
        .collection('friend_requests')
        .where('senderUid', isEqualTo: currentUser.uid)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception("Friend request already sent");
    }

    // 3. Gửi Yêu cầu
    await _firestore
        .collection('users')
        .doc(receiverID)
        .collection('friend_requests')
        .add({
      'senderUid': currentUser.uid,
      'senderEmail': currentUser.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // Chấp nhận yêu cầu kết bạn
  Future<void> acceptFriendRequest(
      String requestID, String senderUid, String senderEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();

    //Thêm người gửi vào danh sách bạn bè
    final currentUserRef = _firestore.collection('users').doc(currentUser.uid);
    batch.update(currentUserRef, {
      'friends': FieldValue.arrayUnion([
        {'uid': senderUid, 'email': senderEmail}
      ])
    });

    // 2. Thêm người dùng hiện tại vào danh sách bạn bè của người gửi
    final senderRef = _firestore.collection('users').doc(senderUid);
    batch.update(senderRef, {
      'friends': FieldValue.arrayUnion([
        {'uid': currentUser.uid, 'email': currentUser.email}
      ])
    });

    // 3. Xóa yêu cầu kết bạn
    final requestRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friend_requests')
        .doc(requestID);
    batch.delete(requestRef);

    await batch.commit();
  }

  // Từ chối yêu cầu kết bạn
  Future<void> rejectFriendRequest(String requestID) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friend_requests')
        .doc(requestID)
        .delete();
  }

  // Tìm kiếm người dùng để truyền vào danh sách (helper)
  // Tìm kiếm tiền tố: vd "a" -> "a...", "ab..."
  Stream<QuerySnapshot> searchUserByEmail(String emailQuery) {
    if (emailQuery.isEmpty) return const Stream.empty();

    String endQuery = '$emailQuery\uf8ff'; // \uf8ff là một ký tự unicode rất cao

    return _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: emailQuery)
        .where('email', isLessThan: endQuery)
        .snapshots();
  }
}
