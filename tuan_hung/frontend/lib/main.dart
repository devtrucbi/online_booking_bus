import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tuan_hung/screens/add_trip_screen.dart';
import 'package:tuan_hung/screens/admin_booking_screen.dart';
import 'package:tuan_hung/screens/admin_trip_screen.dart';
import 'package:tuan_hung/screens/admin_user_screen.dart';
import 'package:tuan_hung/screens/auth/login_screen.dart';
import 'package:tuan_hung/screens/auth/register_screen.dart';
import 'package:tuan_hung/screens/booking_history_screen.dart';
import 'package:tuan_hung/screens/main_screen.dart';
import 'package:tuan_hung/screens/payment_screen.dart';
import 'package:tuan_hung/screens/profile_screen.dart';
import 'package:tuan_hung/screens/seat_seletion_screen.dart';
import 'package:tuan_hung/screens/trip_search_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi_VN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuấn Hưng - Đặt vé xe',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          titleLarge: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(),
        '/trip-search': (context) => const TripSearchScreen(),
        '/seat-selection': (context) => const SeatSelectionScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/booking-history': (context) => const BookingHistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/add-trip': (context) => const AddTripScreen(),
        '/admin/trips': (context) => const AdminTripsScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/bookings': (context) => const AdminBookingsScreen(),
      },
      onUnknownRoute: (settings) {
        // Fallback route if a route is not found
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Trang không tìm thấy')),
                body: Center(
                  child: Text(
                    'Không tìm thấy trang: ${settings.name}',
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ),
              ),
        );
      },
    );
  }
}
