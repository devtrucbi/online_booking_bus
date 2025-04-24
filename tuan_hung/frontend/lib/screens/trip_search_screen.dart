import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tuan_hung/models/trip.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _from;
  String? _to;
  DateTime? _selectedDate;
  List<Trip> _trips = [];
  bool _isLoading = false;

  final List<String> _locations = ['Sài Gòn', 'Cà Mau'];

  @override
  void initState() {
    super.initState();
    _from = _locations[0]; // Mặc định là Sài Gòn
    _to = _locations[1]; // Mặc định là Cà Mau
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _searchTrips() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() {
        _isLoading = true;
        _trips = [];
      });

      try {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('chuyen_xe')
                .where('from', isEqualTo: _from)
                .where('to', isEqualTo: _to)
                .where('date', isEqualTo: formattedDate)
                .get();

        if (mounted) {
          setState(() {
            _trips =
                querySnapshot.docs
                    .map((doc) => Trip.fromJson(doc.data()))
                    .toList()
                  ..sort((a, b) => a.time.compareTo(b.time));
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi tìm kiếm chuyến xe: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn đầy đủ thông tin')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm chuyến xe'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeInUp(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _from,
                      decoration: const InputDecoration(
                        labelText: 'Điểm đi',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _locations
                              .map(
                                (location) => DropdownMenuItem(
                                  value: location,
                                  child: Text(location),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _from = value;
                          _to = _locations.firstWhere(
                            (location) => location != value,
                          );
                        });
                      },
                      validator:
                          (value) =>
                              value == null ? 'Vui lòng chọn điểm đi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _to,
                      decoration: const InputDecoration(
                        labelText: 'Điểm đến',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _locations
                              .map(
                                (location) => DropdownMenuItem(
                                  value: location,
                                  child: Text(location),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _to = value;
                          _from = _locations.firstWhere(
                            (location) => location != value,
                          );
                        });
                      },
                      validator:
                          (value) =>
                              value == null ? 'Vui lòng chọn điểm đến' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày khởi hành',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Chọn ngày'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _searchTrips,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Tìm kiếm'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_trips.isEmpty)
                const Center(child: Text('Không tìm thấy chuyến xe'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      final formattedDate = DateFormat(
                        'dd/MM/yyyy',
                        'vi_VN',
                      ).format(DateTime.parse(trip.date));
                      final formattedPrice = NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'VNĐ',
                        decimalDigits: 0,
                      ).format(trip.price);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            '${trip.from} - ${trip.to}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Ngày: $formattedDate'),
                              Text('Giờ: ${trip.time}'),
                              Text('Loại xe: ${trip.busType}'),
                              Text('Giá: $formattedPrice'),
                              Text('Ghế trống: ${trip.availableSeats.length}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/seat_selection',
                              arguments: {'trip': trip},
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
