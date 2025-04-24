import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String tripId;
  final String from;
  final String to;
  final String date;
  final String seat;
  final int price;
  final String status;
  final String pickupPoint;
  final DateTime? createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.from,
    required this.to,
    required this.date,
    required this.seat,
    required this.price,
    required this.status,
    required this.pickupPoint,
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tripId: json['tripId'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      date: json['date'] as String,
      seat: json['seat'] as String,
      price: json['price'] as int,
      status: json['status'] as String,
      pickupPoint: json['pickupPoint'] as String,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : null,
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
      'seat': seat,
      'price': price,
      'status': status,
      'pickupPoint': pickupPoint,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
    };
  }
}
