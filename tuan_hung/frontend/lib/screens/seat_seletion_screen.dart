import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tuan_hung/models/trip.dart';
import 'package:tuan_hung/widgets/custom_appbar.dart';

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
  late List<String> _allFloor1Seats;
  late List<String> _allFloor2Seats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    _allFloor1Seats = List.generate(15, (index) => 'A${index + 1}');
    _allFloor2Seats = List.generate(15, (index) => 'B${index + 1}');

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
      appBar: CustomAppBar(
        title: 'Chọn ghế - ${_trip.from} → ${_trip.to}',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black87,
          tabs: const [Tab(text: 'Tầng 1'), Tab(text: 'Tầng 2')],
        ),
      ),
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
                        // TabBarView
                        SizedBox(
                          height: constraints.maxHeight * 0.5,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSeatGrid(_allFloor1Seats, 'Tầng 1'),
                              _buildSeatGrid(_allFloor2Seats, 'Tầng 2'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Số ghế đã chọn
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'Số ghế đã chọn: ${_selectedSeats.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Chọn điểm đón
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 100),
                          child:
                              availablePickupPoints.isEmpty
                                  ? const Text(
                                    'Không có điểm đón khả dụng',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontFamily: 'Roboto',
                                    ),
                                  )
                                  : DropdownButtonFormField<String>(
                                    value: _selectedPickupPoint,
                                    decoration: InputDecoration(
                                      labelText: 'Điểm đón',
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.location_on,
                                        color: Colors.black87,
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
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'Roboto',
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
                        ),
                        const SizedBox(height: 20),
                        // Nút tiếp tục
                        ZoomIn(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 200),
                          child: _buildGradientButton(
                            context: context,
                            label: 'Tiếp tục thanh toán',
                            onTap:
                                _selectedSeats.isEmpty ||
                                        _selectedPickupPoint == null
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
                          ),
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

  Widget _buildSeatGrid(List<String> allSeats, String floorLabel) {
    if (allSeats.isEmpty) {
      return Center(
        child: FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Text(
            'Không có ghế ở $floorLabel',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 18,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      );
    }

    allSeats.sort((a, b) {
      final aNumber = int.parse(a.substring(1));
      final bNumber = int.parse(b.substring(1));
      return aNumber.compareTo(bNumber);
    });

    List<Widget> seatRows = [];
    for (int row = 0; row < 5; row++) {
      int startIndex = row * 3;
      seatRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._buildSeatWidgets(allSeats, startIndex, startIndex + 1),
            const SizedBox(width: 20),
            ..._buildSeatWidgets(allSeats, startIndex + 1, startIndex + 2),
            const SizedBox(width: 20),
            ..._buildSeatWidgets(allSeats, startIndex + 2, startIndex + 3),
          ],
        ),
      );
      seatRows.add(const SizedBox(height: 10));
    }

    return SingleChildScrollView(child: Column(children: seatRows));
  }

  List<Widget> _buildSeatWidgets(
    List<String> allSeats,
    int startIndex,
    int endIndex,
  ) {
    List<Widget> widgets = [];
    for (int i = startIndex; i < endIndex && i < allSeats.length; i++) {
      final seat = allSeats[i];
      final isAvailable = _trip.availableSeats.contains(seat);
      final isSelected = _selectedSeats.contains(seat);
      final isBooked = !isAvailable;

      widgets.add(
        BounceInDown(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 50 * i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap:
                  isAvailable
                      ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedSeats.remove(seat);
                          } else {
                            _selectedSeats.add(seat);
                          }
                        });
                      }
                      : null,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      isBooked
                          ? Colors.redAccent
                          : (isSelected ? Colors.green : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isBooked ? Colors.red : Colors.black,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isBooked ? 'X' : seat,
                    style: TextStyle(
                      color:
                          isBooked || isSelected
                              ? Colors.white
                              : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
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
