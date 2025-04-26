import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';
import 'package:animate_do/animate_do.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchBookings();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('bookings').get();
      final bookings = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tripSnapshot =
            await FirebaseFirestore.instance
                .collection('chuyen_xe')
                .doc(data['tripId'])
                .get();
        if (!tripSnapshot.exists) continue;

        final tripData = tripSnapshot.data()!;
        bookings.add({
          'id': doc.id,
          'trip': Trip.fromJson(tripData),
          'selectedSeats': List<String>.from(data['selectedSeats']),
          'totalPrice': data['totalPrice'],
          'bookingDate':
              (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'status': data['status'] ?? 'unknown',
          'userId': data['userId'],
        });
      }
      if (_isMounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy danh sách đặt vé: $e')),
        );
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
      if (_isMounted) {
        setState(() {
          _bookings.removeWhere((booking) => booking['id'] == bookingId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa đặt vé thành công!')));
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa đặt vé: $e')));
      }
    }
  }

  Future<void> _updateBookingStatus(
    String bookingId,
    String currentStatus,
  ) async {
    final newStatus = currentStatus == 'confirmed' ? 'cancelled' : 'confirmed';
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});
      if (_isMounted) {
        setState(() {
          final bookingIndex = _bookings.indexWhere(
            (booking) => booking['id'] == bookingId,
          );
          _bookings[bookingIndex]['status'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật trạng thái thành $newStatus!')),
        );
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Quản lý đặt vé'),
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
                  : _bookings.isEmpty
                  ? const Center(child: Text('Chưa có đặt vé nào'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      final trip = booking['trip'] as Trip;
                      final formattedPrice = NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'VNĐ',
                        decimalDigits: 0,
                      ).format(booking['totalPrice']);
                      return FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: Duration(milliseconds: 100 * index),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tuyến: ${trip.from} → ${trip.to}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Ngày: ${trip.date}'),
                                      Text('Giờ: ${trip.time}'),
                                      Text(
                                        'Ghế: ${booking['selectedSeats'].join(", ")}',
                                      ),
                                      Text('Tổng tiền: $formattedPrice'),
                                      Text('Trạng thái: ${booking['status']}'),
                                      Text(
                                        'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(booking['bookingDate'])}',
                                      ),
                                      Text('Người dùng: ${booking['userId']}'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    booking['status'] == 'confirmed'
                                        ? Icons.cancel
                                        : Icons.check,
                                    color:
                                        booking['status'] == 'confirmed'
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                  onPressed:
                                      () => _updateBookingStatus(
                                        booking['id'],
                                        booking['status'],
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteBooking(booking['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
