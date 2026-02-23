import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  Stream<User?> get authStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;
      await _fireStore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': '',
        'photoUrl': '',
        'dob': null,
        'friends': [],
        'createAt': FieldValue.serverTimestamp(),
      });
      print('add new user success');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.code}');
      rethrow;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.code}');
      rethrow;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
  Future<void> updateUserProfile({
    required String displayName,
    required DateTime? dob,
    String? photoUrl,
  }) async {
    String uid = _auth.currentUser!.uid;
    await _fireStore.collection('users').doc(uid).update({
      'displayName': displayName,
      'dob': dob != null ? Timestamp.fromDate(dob) : null,
      'photoUrl': ?photoUrl,
    });
  }
}
