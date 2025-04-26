import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isAdminRole = false; // Biến mới để lưu vai trò thực tế từ Firestore
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _checkUserRole();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        final role = userDoc.data()!['role'] as String?;
        if (_isMounted) {
          setState(() {
            _isAdminRole = role == 'admin'; // Lưu vai trò thực tế
            _isAdmin = role == 'admin'; // Chế độ ban đầu
            _isLoading = false;
          });
        }
      } else {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi kiểm tra vai trò: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Tuấn Hưng - Đặt vé xe'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.yellow, Colors.amber],
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    mainAxisSize:
                        MainAxisSize.max, // Đảm bảo cột chiếm toàn bộ chiều cao
                    children: [
                      Expanded(
                        // Sử dụng Expanded để SingleChildScrollView chiếm toàn bộ không gian còn lại
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child:
                                _isAdmin ? _buildAdminView() : _buildUserView(),
                          ),
                        ),
                      ),
                      if (_isAdminRole) // Hiển thị nút chuyển đổi chế độ nếu là admin
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ZoomIn(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 1000),
                            child: _buildGradientButton(
                              context: context,
                              label:
                                  _isAdmin
                                      ? 'Chế độ người dùng'
                                      : 'Chế độ admin',
                              onTap: () {
                                if (_isMounted) {
                                  setState(() {
                                    _isAdmin = !_isAdmin; // Chuyển đổi chế độ
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildUserView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        ElasticIn(
          duration: const Duration(milliseconds: 1000),
          child: const Text(
            'Chào mừng đến với Tuấn Hưng',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Mô tả
        FadeInUp(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 200),
          child: const Text(
            'Đặt vé xe dễ dàng, nhanh chóng và an toàn!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Nút tìm kiếm chuyến xe
        ZoomIn(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 400),
          child: _buildGradientButton(
            context: context,
            label: 'Tìm kiếm chuyến xe',
            onTap: () {
              Navigator.pushNamed(context, '/trip-search');
            },
          ),
        ),
        const SizedBox(height: 12),
        // Nút lịch sử đặt vé
        ZoomIn(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 600),
          child: _buildGradientButton(
            context: context,
            label: 'Lịch sử đặt vé',
            onTap: () {
              Navigator.pushNamed(context, '/booking-history');
            },
          ),
        ),
        const SizedBox(height: 12),
        // Nút hồ sơ
        ZoomIn(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 800),
          child: _buildGradientButton(
            context: context,
            label: 'Hồ sơ',
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        ElasticIn(
          duration: const Duration(milliseconds: 1000),
          child: const Text(
            'Trang quản lý - Tuấn Hưng',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Mô tả
        FadeInUp(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 200),
          child: const Text(
            'Quản lý hệ thống đặt vé xe',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Nút quản lý chuyến xe
        ZoomIn(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 400),
          child: _buildGradientButton(
            context: context,
            label: 'Quản lý chuyến xe',
            onTap: () {
              Navigator.pushNamed(context, '/admin/trips');
            },
          ),
        ),
        const SizedBox(height: 12),
        // Nút quản lý người dùng
        ZoomIn(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 600),
          child: _buildGradientButton(
            context: context,
            label: 'Quản lý người dùng',
            onTap: () {
              Navigator.pushNamed(context, '/admin/users');
            },
          ),
        ),
        const SizedBox(height: 12),
        // Nút quản lý đặt vé
        ZoomIn(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 800),
          child: _buildGradientButton(
            context: context,
            label: 'Quản lý đặt vé',
            onTap: () {
              Navigator.pushNamed(context, '/admin/bookings');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white70],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
