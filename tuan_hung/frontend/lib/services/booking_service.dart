import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuan_hung/models/booking.dart';

class BookingService {
  Future<List<Booking>> getUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Vui lòng đăng nhập để xem lịch sử đặt vé');
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user.uid)
              .orderBy(
                'bookingDate',
                descending: true,
              ) // Sắp xếp theo ngày đặt vé
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Kiểm tra các trường bắt buộc
        if (!data.containsKey('trip') ||
            !data.containsKey('selectedSeats') ||
            !data.containsKey('totalPrice') ||
            !data.containsKey('status') ||
            !data.containsKey('pickupPoint') ||
            !data.containsKey('bookingDate')) {
          throw Exception('Dữ liệu đặt vé không đầy đủ: ${doc.id}');
        }

        return Booking.fromJson({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy lịch sử đặt vé: $e');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId);

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final bookingDoc = await transaction.get(bookingRef);

          if (!bookingDoc.exists) {
            throw Exception('Đặt vé không tồn tại');
          }

          final bookingData = bookingDoc.data()!;
          if (bookingData['status'] != 'confirmed') {
            throw Exception('Chỉ có thể hủy vé đang ở trạng thái confirmed');
          }

          // Kiểm tra thời gian chuyến xe
          final tripDateStr = bookingData['trip']['date'] as String;
          final tripTimeStr = bookingData['trip']['time'] as String;
          final tripDateTimeStr =
              '$tripDateStr $tripTimeStr'; // Ví dụ: "25/04/2025 14:00"
          final tripDateTime = DateTime.parse(
            tripDateTimeStr.replaceAll('/', '-'),
          ); // Chuyển thành định dạng yyyy-MM-dd HH:mm
          final now = DateTime.now();

          if (now.isAfter(tripDateTime)) {
            throw Exception('Không thể hủy vé vì chuyến xe đã khởi hành');
          }

          // Cập nhật trạng thái thành "cancelled"
          transaction.update(bookingRef, {'status': 'cancelled'});

          // Khôi phục ghế trong chuyến xe
          final tripRef = FirebaseFirestore.instance
              .collection('chuyen_xe')
              .doc(bookingData['tripId']);
          final tripDoc = await transaction.get(tripRef);

          if (!tripDoc.exists) {
            throw Exception('Chuyến xe không tồn tại');
          }

          final tripData = tripDoc.data()!;
          final availableSeats = List<String>.from(
            tripData['availableSeats'] ?? [],
          );
          final selectedSeats = List<String>.from(
            bookingData['selectedSeats'] ?? [],
          );
          availableSeats.addAll(selectedSeats);
          transaction.update(tripRef, {'availableSeats': availableSeats});
        })
        .catchError((e) {
          throw Exception('Lỗi khi hủy vé: $e');
        });
  }
}
