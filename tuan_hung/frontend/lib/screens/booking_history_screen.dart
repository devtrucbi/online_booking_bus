import 'package:flutter/material.dart';
import 'package:tuan_hung/models/booking.dart';
import 'package:tuan_hung/services/booking_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final bookings = await _bookingService.getUserBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _bookingService.cancelBooking(bookingId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hủy vé thành công')));
      _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi hủy vé: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đặt vé')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _bookings.isEmpty
              ? const Center(child: Text('Chưa có vé nào'))
              : ListView.builder(
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: ListTile(
                      title: Text('${booking.from} -> ${booking.to}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ngày: ${booking.date}'),
                          Text('Ghế: ${booking.seat}'),
                          Text('Trạng thái: ${booking.status}'),
                          Text('Điểm đón: ${booking.pickupPoint}'),
                        ],
                      ),
                      trailing:
                          booking.status == 'Pending'
                              ? IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () => _cancelBooking(booking.id),
                              )
                              : null,
                    ),
                  );
                },
              ),
    );
  }
}
