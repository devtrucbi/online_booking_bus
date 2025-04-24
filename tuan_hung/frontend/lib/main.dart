import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tuan_hung/screens/add_trip_screen.dart';
import 'package:tuan_hung/screens/auth/login_screen.dart';
import 'package:tuan_hung/screens/auth/register_screen.dart';
import 'package:tuan_hung/screens/booking_history_screen.dart';
import 'package:tuan_hung/screens/main_screen.dart';
import 'package:tuan_hung/screens/payment_screen.dart';
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
      title: 'Tuấn Hưng Bus Booking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(),
        '/trip_search': (context) => const TripSearchScreen(),
        '/seat_selection': (context) => const SeatSelectionScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/booking_history': (context) => const BookingHistoryScreen(),
        '/add_trip': (context) => const AddTripScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const MainScreen(); // Điều hướng đến MainScreen nếu đã đăng nhập
          }
          return const LoginScreen(); // Điều hướng đến LoginScreen nếu chưa đăng nhập
        },
      ),
    );
  }
}
