Online Booking Bus - Hướng dẫn cài đặt và chạy ứng dụng
Ứng dụng Online Booking Bus là một hệ thống đặt vé xe buýt trực tuyến, bao gồm:

Frontend: Được xây dựng bằng Flutter, cho phép người dùng tìm kiếm chuyến xe, đặt vé, xem lịch sử đặt vé, và quản lý vé.
Backend: Được xây dựng bằng Node.js, xử lý thanh toán qua VNPay, lưu trữ thông tin đặt vé, và quản lý dữ liệu trên Firestore.
Database: Sử dụng Firebase Firestore để lưu trữ thông tin người dùng, chuyến xe, và đặt vé.

Yêu cầu hệ thống
Trước khi bắt đầu, hãy đảm bảo đã cài đặt các công cụ sau:

Flutter: Phiên bản 3.0.0 hoặc mới hơn. Hướng dẫn cài đặt Flutter
Dart: Đi kèm với Flutter.
Node.js: Phiên bản 16.x hoặc mới hơn. Hướng dẫn cài đặt Node.js
Firebase: Tài khoản Firebase và một dự án đã được tạo. Tạo dự án Firebase
Git: Để clone repository. Cài đặt Git
IDE: Visual Studio Code (khuyến nghị) hoặc Android Studio, với plugin Flutter/Dart được cài đặt.
Thiết bị hoặc trình giả lập: Android/iOS emulator hoặc thiết bị thật để chạy ứng dụng Flutter.

Cấu trúc thư mục
tuan_hung/
├── frontend/           # Frontend (Flutter app)
│   ├── lib/             # Mã nguồn Flutter
│   ├── android/         # Cấu hình Android
│   ├── ios/             # Cấu hình iOS
│   └── pubspec.yaml     # File cấu hình dependencies của Flutter
└── backend/             # Backend (Node.js)
    ├── server.js        # File chính của backend
    ├── package.json     # File cấu hình dependencies của Node.js
    └── tuan-a2941-dbea6d52a35a.json  # Service Account Key của Firebase

Hướng dẫn cài đặt
1. Clone repository
Clone mã nguồn từ repository về máy của bạn:
git clone <repository-url>
cd online_booking_bus

Thay <repository-url> bằng URL của repository của bạn.
2. Thiết lập Firebase
Tạo dự án Firebase

Truy cập Firebase Console.
Tạo một dự án mới (ví dụ: tuan-a2941).
Kích hoạt Firestore Database:
Trong Firebase Console, vào Firestore Database > Create Database.
Chọn chế độ Production và chọn khu vực gần bạn nhất.
Cấu hình quy tắc bảo mật Firestore (xem mục Cấu hình Firestore bên dưới).



Tải Service Account Key (cho backend)

Trong Firebase Console, vào Project Settings > Service Accounts.
Nhấn Generate new private key để tải file JSON (ví dụ: tuan-a2941-dbea6d52a35a.json).
Lưu file này vào thư mục backend/:online_booking_bus/backend/tuan-a2941-dbea6d52a35a.json



Cấu hình Firebase cho Flutter (Frontend)

Cài đặt Firebase CLI (nếu chưa có):npm install -g firebase-tools


Đăng nhập vào Firebase:firebase login


Thêm Firebase vào ứng dụng Flutter:
Trong thư mục tuan_hung/, chạy:flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore


Cài đặt plugin Firebase cho Flutter:dart pub global activate flutterfire_cli


Chạy lệnh để cấu hình Firebase:flutterfire configure

Chọn dự án tuan-a2941 và làm theo hướng dẫn để tạo các file cấu hình (firebase_options.dart).



Cấu hình Firestore

Trong Firebase Console, vào Firestore Database > Rules.
Dán quy tắc bảo mật sau (được lấy từ dự án của bạn):

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    function isValidBookingData() {
      return request.resource.data.keys().hasAll(['tripId', 'userId', 'selectedSeats', 'totalPrice', 'bookingDate', 'status']);
    }

    function isValidPendingBookingData() {
      return request.resource.data.keys().hasAll(['tripId', 'userId', 'selectedSeats', 'totalPrice', 'orderId', 'status']);
    }

    function isValidTripData() {
      return request.resource.data.keys().hasAll(['id', 'from', 'to', 'date', 'time', 'price', 'availableSeats']);
    }

    function isValidUserData() {
      return request.resource.data.keys().hasAll(['email']);
    }

    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || isAdmin());
      allow create: if request.auth != null && request.auth.uid == userId && isValidUserData();
      allow update: if request.auth != null && (request.auth.uid == userId || isAdmin()) && isValidUserData();
      allow delete: if isAdmin();
    }

    match /chuyen_xe/{tripId} {
      allow read: if request.auth != null;
      allow create: if isAdmin() && isValidTripData();
      allow update: if isAdmin() && isValidTripData();
      allow delete: if isAdmin();
    }

    match /bookings/{bookingId} {
      allow read: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid && isValidBookingData();
      allow update: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin()) && isValidBookingData();
      allow delete: if isAdmin();
    }

    match /pending_bookings/{bookingId} {
      allow read: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid && isValidPendingBookingData();
      allow update: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin()) && isValidPendingBookingData();
      allow delete: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin());
    }
  }
}


Nhấn Publish để lưu quy tắc.

3. Cài đặt Backend (Node.js)

Điều hướng đến thư mục backend:
cd backend


Cài đặt các dependencies:
npm install


Đảm bảo file tuan-a2941-dbea6d52a35a.json đã được đặt trong thư mục backend.

Chạy backend:
node server.js

Backend sẽ chạy tại http://localhost:5002.


4. Cài đặt Frontend (Flutter)

Điều hướng đến thư mục tuan_hung:
cd tuan_hung


Cài đặt các dependencies:
flutter pub get


Đảm bảo file firebase_options.dart đã được tạo trong thư mục lib/.

Cấu hình VNPay (nếu sử dụng):

Trong server.js, đảm bảo các thông số VNPay được cấu hình đúng:const vnp_TmnCode = 'H9J5646I';
const vnp_HashSecret = 'HB99Z3ON15OO9XJJ4MJGWKF0Y7LDDPZ8';
const vnp_Url = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
const vnp_ReturnUrl = 'http://localhost:5002/vnpay_return';


Nếu bạn sử dụng VNPay chính thức (không phải sandbox), hãy cập nhật các giá trị trên bằng thông tin từ VNPay.



5. Chạy ứng dụng
Chạy Backend

Mở terminal và chạy backend (nếu chưa chạy):cd backend
node server.js



Chạy Frontend

Mở terminal mới và điều hướng đến thư mục tuan_hung:
cd tuan_hung


Chạy ứng dụng Flutter:
flutter run


Chọn thiết bị (emulator hoặc thiết bị thật) để chạy ứng dụng.


6. Tạo dữ liệu mẫu (Tùy chọn)
Để kiểm tra ứng dụng, bạn có thể tạo dữ liệu mẫu trong Firestore:

Tạo tài liệu trong users:

Trong Firestore, tạo một tài liệu trong users với uid của tài khoản admin:{
    "email": "admin@example.com",
    "role": "admin"
}




Tạo tài liệu trong chuyen_xe:

Tạo một tài liệu trong chuyen_xe:{
    "id": "trip1",
    "from": "Hà Nội",
    "to": "TP.HCM",
    "date": "30/04/2025",
    "time": "14:00",
    "price": 500000,
    "availableSeats": ["A1", "A2", "A3", "A4"]
}




Đăng nhập:

Sử dụng tài khoản admin hoặc tạo tài khoản người dùng để đăng nhập và đặt vé.



Ghi chú

Thanh toán VNPay: Hiện tại, ứng dụng sử dụng VNPay Sandbox. Nếu bạn muốn tích hợp VNPay chính thức, hãy cập nhật thông tin vnp_TmnCode và vnp_HashSecret trong server.js.
Hủy vé: Ứng dụng cho phép hủy vé và phục hồi ghế trong BookingHistoryScreen và AdminBookingsScreen.
Quản lý đặt vé: Admin có thể xem, cập nhật trạng thái, và xóa đặt vé trong AdminBookingsScreen.

Xử lý lỗi thường gặp

Lỗi xác thực Firebase:

Đảm bảo file tuan-a2941-dbea6d52a35a.json được đặt đúng trong thư mục backend.
Kiểm tra thời gian hệ thống trên máy của bạn (phải đồng bộ với thời gian của Google).


Lỗi permission-denied trong Firestore:

Kiểm tra quy tắc bảo mật Firestore và đảm bảo người dùng đã đăng nhập.
Đảm bảo tài khoản admin có role: "admin" trong users.


Backend không phản hồi:

Đảm bảo backend đang chạy tại http://localhost:5002.
Kiểm tra log trong terminal để tìm lỗi.



Đóng góp
Nếu bạn muốn đóng góp vào dự án, hãy tạo pull request hoặc liên hệ với tôi qua email: [your-email@example.com].
Tác giả

Tuan Hung - [your-email@example.com]


