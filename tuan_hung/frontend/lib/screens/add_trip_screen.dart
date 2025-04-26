import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';

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
  bool _isLoading = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
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
    if (_isMounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && _isMounted) {
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
    if (picked != null && _isMounted) {
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
        setState(() {
          _isLoading = true;
        });

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
            .collection('chuyen_xe')
            .doc(trip.id)
            .set(trip.toJson());

        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm chuyến xe thành công')),
          );
          _resetForm();
          Navigator.pop(
            context,
            trip.toJson(),
          ); // Trả về trip cho AdminTripsScreen
        }
      } catch (e) {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    } else {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Thêm chuyến xe'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.yellow, Colors.amber],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.max, // Đảm bảo cột chiếm toàn bộ chiều cao
            children: [
              Expanded(
                // Sử dụng Expanded để SingleChildScrollView chiếm toàn bộ không gian còn lại
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: DropdownButtonFormField<String>(
                              value: _from,
                              decoration: InputDecoration(
                                labelText: 'Điểm đi',
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items:
                                  _locations
                                      .map(
                                        (location) => DropdownMenuItem(
                                          value: location,
                                          child: Text(
                                            location,
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (_isMounted) {
                                  setState(() {
                                    _from = value;
                                    _to = _locations.firstWhere(
                                      (location) => location != value,
                                    );
                                    _pickupPoints.clear();
                                    _updatePickupPoints();
                                  });
                                }
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Vui lòng chọn điểm đi'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 100),
                            child: DropdownButtonFormField<String>(
                              value: _to,
                              decoration: InputDecoration(
                                labelText: 'Điểm đến',
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items:
                                  _locations
                                      .map(
                                        (location) => DropdownMenuItem(
                                          value: location,
                                          child: Text(
                                            location,
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (_isMounted) {
                                  setState(() {
                                    _to = value;
                                    _from = _locations.firstWhere(
                                      (location) => location != value,
                                    );
                                    _pickupPoints.clear();
                                    _updatePickupPoints();
                                  });
                                }
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Vui lòng chọn điểm đến'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 200),
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Ngày khởi hành',
                                  labelStyle: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _selectedDate == null
                                      ? 'Chọn ngày'
                                      : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate!),
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 300),
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Giờ khởi hành',
                                  labelStyle: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _selectedTime == null
                                      ? 'Chọn giờ'
                                      : _selectedTime!.format(context),
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 400),
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Giá vé (VNĐ)',
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty)
                                  return 'Vui lòng nhập giá vé';
                                if (double.tryParse(value) == null ||
                                    double.parse(value) <= 0) {
                                  return 'Giá vé phải là số dương';
                                }
                                return null;
                              },
                              style: const TextStyle(fontFamily: 'Roboto'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 500),
                            child: DropdownButtonFormField<String>(
                              value: _busType,
                              decoration: InputDecoration(
                                labelText: 'Loại xe',
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items:
                                  ['Giường nằm', 'Limousine', 'Ghế ngồi']
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type,
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (_isMounted) {
                                  setState(() {
                                    _busType = value!;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 600),
                            child: Text(
                              'Danh sách ghế: ${_availableSeats.join(", ")}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 700),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedPickupPoint,
                                    decoration: InputDecoration(
                                      labelText: 'Chọn điểm đón',
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    items:
                                        _availablePickupPoints
                                            .map(
                                              (point) => DropdownMenuItem(
                                                value: point,
                                                child: Text(
                                                  point,
                                                  style: const TextStyle(
                                                    fontFamily: 'Roboto',
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      if (_isMounted) {
                                        setState(() {
                                          _selectedPickupPoint = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ZoomIn(
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 750),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.white, Colors.white70],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _addPickupPoint,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          child: const Text(
                                            'Thêm',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 800),
                            child: Wrap(
                              spacing: 8.0,
                              children:
                                  _pickupPoints
                                      .map(
                                        (point) => Chip(
                                          label: Text(
                                            point,
                                            style: const TextStyle(
                                              fontFamily: 'Roboto',
                                              color: Colors.black87,
                                            ),
                                          ),
                                          backgroundColor: Colors.white
                                              .withOpacity(0.8),
                                          deleteIconColor: Colors.red,
                                          onDeleted: () {
                                            if (_isMounted) {
                                              setState(() {
                                                _pickupPoints.remove(point);
                                              });
                                            }
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ZoomIn(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 900),
                  child: _buildGradientButton(
                    context: context,
                    label: _isLoading ? 'Đang lưu...' : 'Thêm chuyến xe',
                    onTap: _isLoading ? null : _submitTrip,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white70],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
