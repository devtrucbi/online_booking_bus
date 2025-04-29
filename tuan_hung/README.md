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

LINK DEMOE: https://youtu.be/GV2G71jPns0
Hướng dẫn cài đặt
1. Clone repository hoặc mã có sẵn
Clone mã nguồn từ repository về máy của bạn:
git clone https://github.com/devtrucbi/online_booking_bus.git
cd online_booking_bus

2. Di chuyển đến folder dự án (/tuan_hung)
- di chuyển đến thư mục /backend, chạy lệnh "npm install" để cài đặt các thư viện cần thiết,
sau đó chạy lệnh "node server.js" để khởi động server
- di chuyển đến thư mục /frontend/function, chạy lệnh "npm install" dể cài đặt thư viện cần thiết, sau đó tiếp tục chạy lệnh "firebase deploy --only functions"
- di chuyển về thư mục /frontend, chạy lệnh "flutter pub get", sau đó chạy lệnh flutter run để thực thi chương trình



Đăng nhập:
Account admin: (email: admin@gmail.com, password: admin123)
Account user: (email: user01@gmail.com, password: user123)

Tài khoản thanh toán có sẵn:
Ngân hàng: NCB
STk: 9704198526191432198
Tên chủ thẻ: NGUYEN VAN A
Ngày phát hàng: 07/15
Mã OTP: 123456

Ghi chú

Thanh toán VNPay: Hiện tại, ứng dụng sử dụng VNPay Sandbox. Nếu bạn muốn tích hợp VNPay chính thức, hãy cập nhật thông tin vnp_TmnCode và vnp_HashSecret trong server.js.

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


Tác giả
Tuan Hung - [trucbicntt0306@gmail.com]


