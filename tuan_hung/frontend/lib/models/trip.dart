class Trip {
  final String id;
  final String from;
  final String to;
  final String date;
  final String time;
  final double price;
  final List<String> availableSeats;
  final List<String> pickupPoints; // Thêm trường pickupPoints
  final String busType; // Thêm trường busType

  Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.price,
    required this.availableSeats,
    required this.pickupPoints,
    required this.busType,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      price: (json['price'] as num).toDouble(),
      availableSeats: List<String>.from(json['availableSeats'] as List),
      pickupPoints: List<String>.from(json['pickupPoints'] as List),
      busType: json['busType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'date': date,
      'time': time,
      'price': price,
      'availableSeats': availableSeats,
      'pickupPoints': pickupPoints,
      'busType': busType,
    };
  }
}
