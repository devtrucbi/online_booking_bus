import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuan_hung/models/booking.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> bookTrip(Booking booking) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toJson());

      final tripRef = _firestore.collection('chuyen_xe').doc(booking.tripId);
      await _firestore.runTransaction((transaction) async {
        final tripDoc = await transaction.get(tripRef);
        if (!tripDoc.exists) {
          throw Exception('Chuyến xe không tồn tại');
        }

        final tripData = tripDoc.data()!;
        final List<String> availableSeats = List<String>.from(
          tripData['availableSeats'] as List<dynamic>,
        );
        final bookedSeats =
            booking.seat.split(', ').map((seat) => seat.trim()).toList();

        for (var seat in bookedSeats) {
          if (!availableSeats.contains(seat)) {
            throw Exception('Ghế $seat đã được đặt bởi người khác');
          }
        }

        final updatedSeats =
            availableSeats
                .where((seat) => !bookedSeats.contains(seat))
                .toList();
        transaction.update(tripRef, {'availableSeats': updatedSeats});
      });
    } catch (e) {
      throw Exception('Lỗi khi đặt vé: $e');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      final bookingDoc = await bookingRef.get();
      if (!bookingDoc.exists) {
        throw Exception('Vé không tồn tại');
      }

      final booking = Booking.fromJson(bookingDoc.data()!);
      if (booking.userId != _auth.currentUser?.uid) {
        throw Exception('Bạn không có quyền hủy vé này');
      }

      await bookingRef.update({'status': 'Cancelled'});

      final tripRef = _firestore.collection('chuyen_xe').doc(booking.tripId);
      await _firestore.runTransaction((transaction) async {
        final tripDoc = await transaction.get(tripRef);
        if (!tripDoc.exists) {
          throw Exception('Chuyến xe không tồn tại');
        }

        final tripData = tripDoc.data()!;
        final List<String> availableSeats = List<String>.from(
          tripData['availableSeats'] as List<dynamic>,
        );
        final cancelledSeats =
            booking.seat.split(', ').map((seat) => seat.trim()).toList();

        final updatedSeats = [...availableSeats, ...cancelledSeats];
        transaction.update(tripRef, {'availableSeats': updatedSeats});
      });
    } catch (e) {
      throw Exception('Lỗi khi hủy vé: $e');
    }
  }

  Future<List<Booking>> getUserBookings() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập. Vui lòng đăng nhập để tiếp tục.');
    }

    try {
      final querySnapshot =
          await _firestore
              .collection('bookings')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy lịch sử đặt vé: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái vé: $e');
    }
  }
}
