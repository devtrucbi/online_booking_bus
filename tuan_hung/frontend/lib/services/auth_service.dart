import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập bằng email và mật khẩu
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Đăng ký bằng email và mật khẩu
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required Function(String error) onError,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Lưu vai trò người dùng vào Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email.trim(),
          'role': 'user', // Mặc định là user, có thể chỉnh thành admin thủ công
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy vai trò của người dùng
  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
