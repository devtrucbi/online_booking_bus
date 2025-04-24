import 'package:flutter/material.dart';
import 'package:tuan_hung/models/trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text('${trip.from} -> ${trip.to}'),
        subtitle: Text(
          'Ngày: ${trip.date} | Giờ: ${trip.time} | Giá: ${trip.price} VNĐ',
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
