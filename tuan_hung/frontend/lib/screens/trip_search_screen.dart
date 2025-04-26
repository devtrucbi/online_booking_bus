import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';

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
  String _errorMessage = '';
  bool _isMounted = false; // Track if the widget is mounted

  final List<String> _locations = ['Sài Gòn', 'Cà Mau'];

  @override
  void initState() {
    super.initState();
    _from = _locations[0]; // Mặc định là Sài Gòn
    _to = _locations[1]; // Mặc định là Cà Mau
    _isMounted = true; // Set to true when the widget is initialized
  }

  @override
  void dispose() {
    _isMounted = false; // Set to false when the widget is disposed
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && _isMounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _searchTrips() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      if (!_isMounted) return; // Exit early if widget is already disposed

      setState(() {
        _isLoading = true;
        _trips = [];
        _errorMessage = '';
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

        if (_isMounted) {
          setState(() {
            _trips =
                querySnapshot.docs
                    .map((doc) => Trip.fromJson(doc.data()))
                    .toList()
                  ..sort((a, b) => a.time.compareTo(b.time));
            _isLoading = false;
          });
        }
      } catch (e) {
        if (_isMounted) {
          setState(() {
            _errorMessage = 'Lỗi khi tìm kiếm chuyến xe: $e';
            _isLoading = false;
          });
        }
      }
    } else {
      if (_isMounted) {
        setState(() {
          _errorMessage = 'Vui lòng chọn đầy đủ thông tin';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Tìm kiếm chuyến xe'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.yellow, Colors.amber],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form tìm kiếm
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Điểm đi
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                child: DropdownButtonFormField<String>(
                                  value: _from,
                                  decoration: InputDecoration(
                                    labelText: 'Điểm đi',
                                    labelStyle: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.location_on,
                                      color: Colors.black87,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 12,
                                    ),
                                  ),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black87,
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
                                    if (_isMounted) {
                                      setState(() {
                                        _from = value;
                                        _to = _locations.firstWhere(
                                          (location) => location != value,
                                        );
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
                              const SizedBox(height: 16),
                              // Điểm đến
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 150),
                                child: DropdownButtonFormField<String>(
                                  value: _to,
                                  decoration: InputDecoration(
                                    labelText: 'Điểm đến',
                                    labelStyle: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.location_on,
                                      color: Colors.black87,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 12,
                                    ),
                                  ),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black87,
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
                                    if (_isMounted) {
                                      setState(() {
                                        _to = value;
                                        _from = _locations.firstWhere(
                                          (location) => location != value,
                                        );
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
                              const SizedBox(height: 16),
                              // Ngày khởi hành
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 300),
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Ngày khởi hành',
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.black87,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 12,
                                          ),
                                    ),
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Chọn ngày'
                                          : DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedDate!),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontFamily: 'Roboto',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Nút tìm kiếm
                              ZoomIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 450),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white, Colors.white70],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _searchTrips,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Tìm kiếm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Hiển thị kết quả
                        if (_isLoading)
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.black87,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        else if (_errorMessage.isNotEmpty)
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ZoomIn(
                                    duration: const Duration(milliseconds: 500),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            Colors.white70,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _searchTrips,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.black87,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Thử lại',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_trips.isEmpty)
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: const Center(
                              child: Text(
                                'Không tìm thấy chuyến xe',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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

                              return FadeInUp(
                                duration: const Duration(milliseconds: 500),
                                delay: Duration(milliseconds: 100 * index),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.white, Colors.white70],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(
                                        16.0,
                                      ),
                                      leading: const Icon(
                                        Icons.directions_bus,
                                        color: Colors.black87,
                                        size: 40,
                                      ),
                                      title: Text(
                                        '${trip.from} → ${trip.to}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            'Ngày: $formattedDate',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Giờ: ${trip.time}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Loại xe: ${trip.busType}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Giá: $formattedPrice',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Ghế trống: ${trip.availableSeats.length}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontFamily: 'Roboto',
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: ZoomIn(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.yellow,
                                                Colors.amber,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (_isMounted) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/seat-selection',
                                                  arguments: {'trip': trip},
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              foregroundColor: Colors.black87,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Chọn chuyến',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
    );
  }
}
