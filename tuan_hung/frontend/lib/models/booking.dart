import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String tripId;
  final String from;
  final String to;
  final String? date; // Làm tùy chọn
  final String? time; // Làm tùy chọn
  final List<String> selectedSeats;
  final int totalPrice;
  final String status;
  final String pickupPoint;
  final String paymentMethod;
  final DateTime bookingDate;

  Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.from,
    required this.to,
    this.date, // Làm tùy chọn
    this.time, // Làm tùy chọn
    required this.selectedSeats,
    required this.totalPrice,
    required this.status,
    required this.pickupPoint,
    required this.paymentMethod,
    required this.bookingDate,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tripId: json['tripId'] as String,
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      date: json['date'] as String?,
      time: json['time'] as String? ?? '',
      selectedSeats:
          (json['selectedSeats'] as List<dynamic>?)?.cast<String>() ?? [],
      totalPrice: json['totalPrice'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      pickupPoint: json['pickupPoint'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      bookingDate:
          (json['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tripId': tripId,
      'from': from,
      'to': to,
      'date': date,
      'time': time,
      'selectedSeats': selectedSeats,
      'totalPrice': totalPrice,
      'status': status,
      'pickupPoint': pickupPoint,
      'paymentMethod': paymentMethod,
      'bookingDate': Timestamp.fromDate(bookingDate),
    };
  }
}
