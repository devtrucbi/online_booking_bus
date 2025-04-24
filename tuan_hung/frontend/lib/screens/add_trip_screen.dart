import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _from;
  String? _to;
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _busType = 'Giường nằm';
  final List<String> _availableSeats = [];
  final List<String> _pickupPoints = [];
  String? _selectedPickupPoint;
  String? _userRole;
  final List<String> _locations = ['Sài Gòn', 'Cà Mau'];
  List<String> _availablePickupPoints = [];

  @override
  void initState() {
    super.initState();
    _from = _locations[0]; // Mặc định là Sài Gòn
    _to = _locations[1]; // Mặc định là Cà Mau
    _updatePickupPoints();
    _generateSeats();
    _fetchUserRole();
  }

  void _generateSeats() {
    _availableSeats.clear();
    for (int i = 1; i <= 15; i++) {
      _availableSeats.add('A$i');
      _availableSeats.add('B$i');
    }
  }

  void _updatePickupPoints() {
    if (_from == 'Sài Gòn') {
      _availablePickupPoints = [
        'Quận 1',
        'Quận Bình Thạnh',
        'Quận Tân Bình',
        'Quận 6',
        'Quận 10',
        'Bến xe Miền Tây',
      ];
    } else {
      _availablePickupPoints = ['Bến xe Cà Mau', 'Bến xe Năm Căn'];
    }
    _selectedPickupPoint = _availablePickupPoints[0];
  }

  void _addPickupPoint() {
    if (_selectedPickupPoint != null &&
        !_pickupPoints.contains(_selectedPickupPoint)) {
      setState(() {
        _pickupPoints.add(_selectedPickupPoint!);
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _priceController.clear();
      _busType = 'Giường nằm';
      _pickupPoints.clear();
      _generateSeats();
      _updatePickupPoints();
    });
  }

  Future<void> _fetchUserRole() async {
    final role = await AuthService().getUserRole();
    setState(() {
      _userRole = role;
    });
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

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitTrip() async {
    if (_userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ admin mới có thể thêm chuyến xe')),
      );
      Navigator.pop(context);
      return;
    }

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _availableSeats.isNotEmpty &&
        _pickupPoints.isNotEmpty) {
      try {
        final dateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        final trip = Trip(
          id: const Uuid().v4(),
          from: _from!,
          to: _to!,
          date: DateFormat('yyyy-MM-dd').format(dateTime),
          time: DateFormat('HH:mm').format(dateTime),
          price: double.parse(_priceController.text.trim()),
          availableSeats: _availableSeats,
          pickupPoints: _pickupPoints,
          busType: _busType,
        );

        await FirebaseFirestore.instance
            .collection('chuyen_xe') // Đổi tên collection thành chuyen_xe
            .doc(trip.id)
            .set(trip.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm chuyến xe thành công')),
        );
        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chuyến xe'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeInUp(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                        _pickupPoints.clear();
                        _updatePickupPoints();
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
                        _pickupPoints.clear();
                        _updatePickupPoints();
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Giờ khởi hành',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'Chọn giờ'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá vé (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Vui lòng nhập giá vé';
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Giá vé phải là số dương';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _busType,
                    decoration: const InputDecoration(
                      labelText: 'Loại xe',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ['Giường nằm', 'Limousine', 'Ghế ngồi']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _busType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Danh sách ghế: ${_availableSeats.join(", ")}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPickupPoint,
                          decoration: const InputDecoration(
                            labelText: 'Chọn điểm đón',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _availablePickupPoints
                                  .map(
                                    (point) => DropdownMenuItem(
                                      value: point,
                                      child: Text(point),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPickupPoint = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addPickupPoint,
                        child: const Text('Thêm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children:
                        _pickupPoints
                            .map(
                              (point) => Chip(
                                label: Text(point),
                                onDeleted: () {
                                  setState(() {
                                    _pickupPoints.remove(point);
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitTrip,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Thêm chuyến xe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}
