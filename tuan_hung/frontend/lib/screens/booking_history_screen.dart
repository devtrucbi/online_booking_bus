import 'package:flutter/material.dart';
import 'package:tuan_hung/models/booking.dart';
import 'package:tuan_hung/services/booking_service.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';
import 'package:animate_do/animate_do.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Lịch sử đặt vé'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.yellow, Colors.amber],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Booking>>(
            future: bookingService.getUserBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Roboto',
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có lịch sử đặt vé',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      color: Colors.black54,
                    ),
                  ),
                );
              }

              final bookings = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];

                  return FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chuyến xe: ${booking.from} - ${booking.to}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ngày: ${booking.date} - ${booking.time}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ghế: ${booking.selectedSeats.join(", ")}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tổng tiền: ${booking.totalPrice} VNĐ',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Phương thức thanh toán: ${booking.paymentMethod}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ngày đặt: ${booking.bookingDate.toString()}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trạng thái: ${booking.status}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            if (booking.status == 'confirmed') ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await bookingService.cancelBooking(
                                          booking.id,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Hủy vé thành công'),
                                          ),
                                        );
                                        // Cập nhật giao diện
                                        (context as Element).markNeedsBuild();
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Lỗi: $e')),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Hủy vé',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
