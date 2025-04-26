import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/screens/add_trip_screen.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';
import 'package:animate_do/animate_do.dart';

class AdminTripsScreen extends StatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  State<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends State<AdminTripsScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchTrips();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _fetchTrips() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('chuyen_xe').get();
      final trips =
          snapshot.docs.map((doc) => Trip.fromJson(doc.data())).toList();
      if (_isMounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy danh sách chuyến xe: $e')),
        );
      }
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chuyen_xe')
          .doc(tripId)
          .delete();
      if (_isMounted) {
        setState(() {
          _trips.removeWhere((trip) => trip.id == tripId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa chuyến xe thành công!')),
        );
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa chuyến xe: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Quản lý chuyến xe'),
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
                  : _trips.isEmpty
                  ? const Center(child: Text('Chưa có chuyến xe nào'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
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
                                        'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(trip.price)}',
                                      ),
                                      Text(
                                        'Ghế trống: ${trip.availableSeats.join(", ")}',
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteTrip(trip.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Điều hướng đến AddTripScreen và chờ kết quả
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTripScreen()),
          );
          // Nếu có kết quả trả về (newTrip), cập nhật danh sách
          if (result != null && _isMounted) {
            setState(() {
              _trips.add(Trip.fromJson(result as Map<String, dynamic>));
            });
          }
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }
}
