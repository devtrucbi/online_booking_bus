import 'package:flutter/material.dart';
import 'package:tuan_hung/screens/booking_history_screen.dart';
import 'package:tuan_hung/screens/profile_screen.dart';
import 'package:tuan_hung/screens/trip_search_screen.dart';
import 'package:tuan_hung/services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userRole;

  final List<Widget> _screens = [
    const TripSearchScreen(),
    const BookingHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      // Kiểm tra xem widget có còn trong cây widget không
      setState(() {
        _userRole = role;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuấn Hưng Bus Booking'),
        actions: [
          if (_userRole == 'admin') // Hiển thị nút nếu là admin
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                Navigator.pushNamed(context, '/add_trip');
              },
              tooltip: 'Thêm chuyến xe',
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
