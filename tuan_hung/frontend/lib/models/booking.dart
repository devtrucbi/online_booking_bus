import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String tripId;
  final String from;
  final String to;
  final String date;
  final String time;
  final List<String>
  selectedSeats; // Đổi từ seat (String) thành selectedSeats (List<String>)
  final int totalPrice; // Đổi từ price thành totalPrice
  final String status;
  final String pickupPoint;
  final String paymentMethod; // Thêm paymentMethod
  final DateTime bookingDate; // Đổi từ createdAt thành bookingDate

  Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.selectedSeats,
    required this.totalPrice,
    required this.status,
    required this.pickupPoint,
    required this.paymentMethod,
    required this.bookingDate,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Lấy thông tin chuyến xe từ trường 'trip' (nếu có)
    final trip = json['trip'] as Map<String, dynamic>? ?? {};

    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tripId: json['tripId'] as String,
      from: trip['from'] as String? ?? json['from'] as String,
      to: trip['to'] as String? ?? json['to'] as String,
      date: trip['date'] as String? ?? json['date'] as String,
      time: trip['time'] as String? ?? json['time'] as String? ?? '',
      selectedSeats:
          (json['selectedSeats'] as List<dynamic>?)?.cast<String>() ?? [],
      totalPrice: json['totalPrice'] as int,
      status: json['status'] as String,
      pickupPoint: json['pickupPoint'] as String,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      bookingDate: (json['bookingDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tripId': tripId,
      'trip': {'from': from, 'to': to, 'date': date, 'time': time},
      'selectedSeats': selectedSeats,
      'totalPrice': totalPrice,
      'status': status,
      'pickupPoint': pickupPoint,
      'paymentMethod': paymentMethod,
      'bookingDate': Timestamp.fromDate(bookingDate),
    };
  }
}
