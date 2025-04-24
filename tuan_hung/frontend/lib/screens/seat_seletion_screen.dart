import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tuan_hung/models/trip.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with SingleTickerProviderStateMixin {
  late Trip _trip;
  List<String> _selectedSeats = [];
  String? _selectedPickupPoint;
  late TabController _tabController;
  late List<String> _floor1Seats; // Ghế tầng 1 (A)
  late List<String> _floor2Seats; // Ghế tầng 2 (B)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy Map từ arguments và truy cập key 'trip'
    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments == null) {
      // Xử lý trường hợp arguments là null
      Navigator.pop(context);
      return;
    }
    final tripData = arguments as Map<String, dynamic>;
    _trip = tripData['trip'] as Trip;

    // Tách ghế thành tầng 1 (A) và tầng 2 (B)
    _floor1Seats =
        _trip.availableSeats.where((seat) => seat.startsWith('A')).toList();
    _floor2Seats =
        _trip.availableSeats.where((seat) => seat.startsWith('B')).toList();

    // Nếu có pickupPoints, chọn điểm đón mặc định
    if (_trip.pickupPoints.isNotEmpty) {
      _selectedPickupPoint = _trip.pickupPoints[0];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availablePickupPoints = _trip.pickupPoints;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn ghế - ${_trip.from} → ${_trip.to}'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Tầng 1'), Tab(text: 'Tầng 2')],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeInUp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TabBarView để hiển thị ghế theo tầng
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tầng 1
                    _buildSeatGrid(_floor1Seats, 'Tầng 1'),
                    // Tầng 2
                    _buildSeatGrid(_floor2Seats, 'Tầng 2'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn điểm đón:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Kiểm tra nếu không có điểm đón
              availablePickupPoints.isEmpty
                  ? const Text(
                    'Không có điểm đón khả dụng',
                    style: TextStyle(color: Colors.red),
                  )
                  : DropdownButtonFormField<String>(
                    value: _selectedPickupPoint,
                    decoration: const InputDecoration(
                      labelText: 'Điểm đón',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        availablePickupPoints
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _selectedSeats.isEmpty || _selectedPickupPoint == null
                        ? null
                        : () {
                          Navigator.pushNamed(
                            context,
                            '/payment',
                            arguments: {
                              'trip': _trip,
                              'selectedSeats': _selectedSeats,
                              'pickupPoint': _selectedPickupPoint,
                            },
                          );
                        },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Tiếp tục thanh toán'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatGrid(List<String> seats, String floorLabel) {
    if (seats.isEmpty) {
      return Center(child: Text('Không có ghế trống ở $floorLabel'));
    }

    // Sắp xếp ghế theo số (VD: A1, A2, A3, ...)
    seats.sort((a, b) {
      final aNumber = int.parse(a.substring(1));
      final bNumber = int.parse(b.substring(1));
      return aNumber.compareTo(bNumber);
    });

    // Mỗi tầng có 5 hàng, mỗi hàng 3 ghế (1-1-1)
    List<Widget> seatRows = [];
    for (int row = 0; row < 5; row++) {
      int startIndex = row * 3;
      seatRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._buildSeatWidgets(seats, startIndex, startIndex + 1), // Ghế 1
            const SizedBox(width: 20), // Khoảng trống
            ..._buildSeatWidgets(
              seats,
              startIndex + 1,
              startIndex + 2,
            ), // Ghế 2
            const SizedBox(width: 20), // Khoảng trống
            ..._buildSeatWidgets(
              seats,
              startIndex + 2,
              startIndex + 3,
            ), // Ghế 3
          ],
        ),
      );
      seatRows.add(const SizedBox(height: 10)); // Khoảng cách giữa các hàng
    }

    return SingleChildScrollView(child: Column(children: seatRows));
  }

  List<Widget> _buildSeatWidgets(
    List<String> seats,
    int startIndex,
    int endIndex,
  ) {
    List<Widget> widgets = [];
    for (int i = startIndex; i < endIndex && i < seats.length; i++) {
      final seat = seats[i];
      final isSelected = _selectedSeats.contains(seat);
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedSeats.remove(seat);
                } else {
                  _selectedSeats.add(seat);
                }
              });
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  seat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
