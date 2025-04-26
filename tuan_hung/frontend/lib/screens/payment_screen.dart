import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:animate_do/animate_do.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Trip _trip;
  late List<String> _selectedSeats;
  late String _pickupPoint;
  bool _isLoading = false;
  String _selectedPaymentMethod = 'VNPay';
  String? _paymentUrl;
  bool _showWebView = false;
  bool _isWebViewLoading = true;
  late WebViewController _webViewController;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('myapp://payment')) {
                  _handlePaymentResult(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onPageStarted: (String url) {
                if (_isMounted) {
                  setState(() {
                    _isWebViewLoading = true;
                  });
                }
              },
              onPageFinished: (String url) {
                if (_isMounted) {
                  setState(() {
                    _isWebViewLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (_isMounted) {
                  setState(() {
                    _isWebViewLoading = false;
                    _showWebView = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lỗi tải trang thanh toán: ${error.description}',
                      ),
                      action: SnackBarAction(
                        label: 'Thử lại',
                        onPressed: _createPaymentUrl,
                      ),
                    ),
                  );
                }
              },
            ),
          );
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments == null) {
      Navigator.pop(context);
      return;
    }

    final tripData = arguments as Map<String, dynamic>;
    _trip = tripData['trip'] as Trip;
    final seats = tripData['selectedSeats'];
    _selectedSeats = seats != null ? List<String>.from(seats) : [];
    _pickupPoint = tripData['pickupPoint'] as String? ?? 'Không xác định';
  }

  Future<void> _createPaymentUrl() async {
    if (!_isMounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để đặt vé')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    if (_selectedPaymentMethod == 'Tiền mặt') {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Xác nhận thanh toán bằng tiền mặt'),
              content: const Text(
                'Bạn sẽ thanh toán bằng tiền mặt khi lên xe. Tiếp tục?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedPaymentMethod == 'Tiền mặt') {
        await _bookTicket();
        if (_isMounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đặt vé thành công!')));
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
        return;
      }

      final totalPrice = _trip.price * _selectedSeats.length;
      final response = await http.post(
        Uri.parse('http://localhost:5002/create_payment_url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tripId': _trip.id,
          'userId': user.uid,
          'selectedSeats': _selectedSeats,
          'pickupPoint': _pickupPoint,
          'totalPrice': totalPrice,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (_isMounted) {
          setState(() {
            _paymentUrl = data['paymentUrl'];
            _showWebView = true;
            _webViewController.loadRequest(Uri.parse(_paymentUrl!));
          });
        }
      } else {
        throw Exception('Không thể tạo URL thanh toán: ${response.body}');
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _createPaymentUrl,
            ),
          ),
        );
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _bookTicket() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_isMounted) return;

    final totalPrice = _trip.price * _selectedSeats.length;
    final bookingData = {
      'tripId': _trip.id,
      'userId': user.uid,
      'selectedSeats': _selectedSeats,
      'pickupPoint': _pickupPoint,
      'totalPrice': totalPrice,
      'paymentMethod': _selectedPaymentMethod,
      'status': 'Đã thanh toán',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('bookings').add(bookingData);

    final updatedSeats =
        _trip.availableSeats
            .where((seat) => !_selectedSeats.contains(seat))
            .toList();
    await FirebaseFirestore.instance
        .collection('chuyen_xe')
        .doc(_trip.id)
        .update({'availableSeats': updatedSeats});
  }

  void _handlePaymentResult(String url) {
    if (!_isMounted) return;

    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];

    if (status == null) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không xác định được trạng thái thanh toán!'),
          ),
        );
        setState(() {
          _showWebView = false;
        });
      }
      return;
    }

    if (status == 'success') {
      _bookTicket();
      if (_isMounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thanh toán thành công!')));
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      if (_isMounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thanh toán thất bại!')));
        setState(() {
          _showWebView = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _trip.price * _selectedSeats.length;
    final formattedPrice = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
      decimalDigits: 0,
    ).format(totalPrice);

    if (_showWebView && _paymentUrl != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Thanh toán VNPay'),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isWebViewLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.black87),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Thanh toán'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.yellow, Colors.amber],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin chuyến xe
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: const Text(
                      'Thông tin chuyến xe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 100),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.directions_bus,
                                color: Colors.black87,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tuyến: ${_trip.from} → ${_trip.to}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ngày: ${_trip.date}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    Text(
                                      'Giờ: ${_trip.time}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    Text(
                                      'Ghế: ${_selectedSeats.join(", ")}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    Text(
                                      'Điểm đón: $_pickupPoint',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    Text(
                                      'Tổng tiền: $formattedPrice',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Phương thức thanh toán
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 300),
                    child: DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Chọn phương thức',
                        labelStyle: const TextStyle(
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                        prefixIcon: const Icon(
                          Icons.payment,
                          color: Colors.black87,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'VNPay', child: Text('VNPay')),
                        DropdownMenuItem(
                          value: 'Tiền mặt',
                          child: Text('Tiền mặt'),
                        ),
                      ],
                      onChanged: (value) {
                        if (_isMounted) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nút xác nhận
                  ZoomIn(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 400),
                    child: _buildGradientButton(
                      context: context,
                      label:
                          _isLoading ? 'Đang xử lý...' : 'Xác nhận thanh toán',
                      onTap:
                          _isLoading || _selectedSeats.isEmpty
                              ? null
                              : _createPaymentUrl,
                    ),
                  ),
                  const SizedBox(height: 20), // Đảm bảo không gian cuối cùng
                ],
              ),
            ),
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
