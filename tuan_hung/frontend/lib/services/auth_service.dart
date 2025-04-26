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

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          throw Exception('Không tìm thấy thông tin người dùng');
        }

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return {
          'name': userData['name'] ?? user.displayName ?? 'Không có tên',
          'email': userData['email'] ?? user.email ?? 'Không có email',
          'phoneNumber': userData['phoneNumber'] ?? 'Không có số điện thoại',
        };
      } else {
        throw Exception('Không tìm thấy người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin người dùng: $e');
    }
  }

  // Đăng ký bằng email và mật khẩu
  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required Function(String) onError,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Thành công
    } catch (e) {
      onError(e.toString());
      return e.toString(); // Trả về lỗi
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
