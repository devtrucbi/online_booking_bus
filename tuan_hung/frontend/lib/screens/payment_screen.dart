import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:tuan_hung/models/trip.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  String _selectedPaymentMethod = 'VNPay'; // Mặc định là VNPay
  String? _paymentUrl;
  bool _showWebView = false;
  late WebViewController _webViewController; // Thêm controller cho WebView

  @override
  void initState() {
    super.initState();
    // Khởi tạo WebViewController
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(
            JavaScriptMode.unrestricted,
          ) // Sửa JavascriptMode thành JavaScriptMode
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('myapp://payment')) {
                  _handlePaymentResult(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy arguments từ navigation
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
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để đặt vé');
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
        setState(() {
          _paymentUrl = data['paymentUrl'];
          _showWebView = true;
          // Load URL vào WebView
          _webViewController.loadRequest(Uri.parse(_paymentUrl!));
        });
      } else {
        throw Exception('Không thể tạo URL thanh toán: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];

    if (status == 'success') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanh toán thành công!')));
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanh toán thất bại!')));
      setState(() {
        _showWebView = false;
      });
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
        appBar: AppBar(
          title: const Text('Thanh toán VNPay'),
          backgroundColor: Colors.blue,
        ),
        body: WebViewWidget(
          controller: _webViewController,
        ), // Sử dụng WebViewWidget
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin chuyến xe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tuyến: ${_trip.from} → ${_trip.to}'),
                              Text('Ngày: ${_trip.date}'),
                              Text('Giờ: ${_trip.time}'),
                              Text('Ghế: ${_selectedSeats.join(", ")}'),
                              Text('Điểm đón: $_pickupPoint'),
                              Text('Tổng tiền: $formattedPrice'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Phương thức thanh toán',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Chọn phương thức',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'VNPay',
                            child: Text('VNPay'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            _selectedSeats.isEmpty ? null : _createPaymentUrl,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Xác nhận thanh toán'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
