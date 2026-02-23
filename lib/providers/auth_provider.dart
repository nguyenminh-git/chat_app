import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStream => _auth.authStateChanges();

  // Đăng ký người dùng mới
  Future<bool> registerWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      
      String uid = userCredential.user!.uid;
      
      // Tạo document profile
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': '',
        'photoUrl': '',
        'dob': null,
        'friends': [],
        'createAt': FieldValue.serverTimestamp(),
      });
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Đăng ký thất bại: ${e.code}');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Lỗi không xác định: $e');
      _setLoading(false);
      return false;
    }
  }

  // Đăng nhập
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Đăng nhập thất bại: ${e.code}');
      _setLoading(false);
      return false;
    } catch (e) {
       _setError('Lỗi không xác định: $e');
      _setLoading(false);
      return false;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners(); // Cập nhật lại UI nếu cần
  }

  // Cập nhật Profile
  Future<void> updateUserProfile({
    required String displayName,
    required DateTime? dob,
    String? photoUrl,
  }) async {
    if (currentUser == null) return;
    
    String uid = currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
      'dob': dob != null ? Timestamp.fromDate(dob) : null,
      'photoUrl': ?photoUrl,
    });
    
    // Ở những app lớn ta sẽ tách hàm này ra UserProvider,
    // Nhưng hiện tại giữ tương thích với AuthService cũ
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners(); // Không bắt buộc, nhưng để clean state
  }
}
