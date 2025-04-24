const express = require('express');
const admin = require('firebase-admin');
const crypto = require('crypto');
const app = express();
const port = 5002;

// Khởi tạo Firebase Admin
const serviceAccount = require('./tuan-a2941-firebase-adminsdk-fbsvc-39093a509d.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Middleware để parse JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cấu hình VNPay
const vnp_TmnCode = 'H9J5646I';
const vnp_HashSecret = 'HB99Z3ON15OO9XJJ4MJGWKF0Y7LDDPZ8'; 
const vnp_Url = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
const vnp_ReturnUrl = 'http://localhost:5002/vnpay_return'; 

// API tạo URL thanh toán VNPay
app.post('/create_payment_url', async (req, res) => {
  const { tripId, userId, selectedSeats, pickupPoint, totalPrice } = req.body;

  if (!tripId || !userId || !selectedSeats || !pickupPoint || !totalPrice) {
    return res.status(400).json({ error: 'Thiếu thông tin cần thiết' });
  }

  // Tạo mã đơn hàng (orderId) duy nhất
  const orderId = `${Date.now()}_${userId}`;
  const createDate = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14); // Format: YYYYMMDDHHmmss

  // Tạo các tham số cho VNPay
  let vnp_Params = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: vnp_TmnCode,
    vnp_Amount: totalPrice * 100, // VNPay yêu cầu số tiền nhân 100 (VNĐ)
    vnp_CreateDate: createDate,
    vnp_CurrCode: 'VND',
    vnp_IpAddr: req.ip || '127.0.0.1',
    vnp_Locale: 'vn',
    vnp_OrderInfo: `Thanh toan don hang ${orderId}`,
    vnp_OrderType: 'Vé Xe', // Loại hàng hóa: vé xe
    vnp_ReturnUrl: vnp_ReturnUrl,
    vnp_TxnRef: orderId,
  };

  // Sắp xếp tham số theo thứ tự alphabet
  vnp_Params = sortObject(vnp_Params);

  // Tạo chữ ký (checksum)
  const signData = Object.keys(vnp_Params)
    .map(key => `${key}=${encodeURIComponent(vnp_Params[key]).replace(/%20/g, '+')}`)
    .join('&');
  const hmac = crypto.createHmac('sha512', vnp_HashSecret);
  const vnp_SecureHash = hmac.update(signData).digest('hex');
  vnp_Params['vnp_SecureHash'] = vnp_SecureHash;

  // Tạo URL thanh toán
  const queryString = Object.keys(vnp_Params)
    .map(key => `${key}=${encodeURIComponent(vnp_Params[key]).replace(/%20/g, '+')}`)
    .join('&');
  const paymentUrl = `${vnp_Url}?${queryString}`;

  // Lưu thông tin đặt vé tạm thời (trước khi thanh toán)
  await db.collection('pending_bookings').doc(orderId).set({
    userId,
    tripId,
    selectedSeats,
    pickupPoint,
    totalPrice,
    orderId,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.json({ paymentUrl });
});

// API xử lý callback từ VNPay
app.get('/vnpay_return', async (req, res) => {
  let vnp_Params = req.query;
  const secureHash = vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  // Sắp xếp tham số
  vnp_Params = sortObject(vnp_Params);

  // Tạo chữ ký để kiểm tra
  const signData = Object.keys(vnp_Params)
    .map(key => `${key}=${encodeURIComponent(vnp_Params[key]).replace(/%20/g, '+')}`)
    .join('&');
  const hmac = crypto.createHmac('sha512', vnp_HashSecret);
  const checkSum = hmac.update(signData).digest('hex');

  const orderId = vnp_Params['vnp_TxnRef'];
  const responseCode = vnp_Params['vnp_ResponseCode'];

  // Kiểm tra chữ ký và trạng thái giao dịch
  if (secureHash === checkSum && responseCode === '00') {
    // Thanh toán thành công
    const pendingBookingRef = db.collection('pending_bookings').doc(orderId);
    const pendingBooking = await pendingBookingRef.get();

    if (!pendingBooking.exists) {
      return res.status(400).json({ error: 'Đơn hàng không tồn tại' });
    }

    const bookingData = pendingBooking.data();

    // Lưu thông tin đặt vé vào Firestore
    await db.collection('bookings').add({
      userId: bookingData.userId,
      tripId: bookingData.tripId,
      selectedSeats: bookingData.selectedSeats,
      pickupPoint: bookingData.pickupPoint,
      totalPrice: bookingData.totalPrice,
      paymentMethod: 'VNPay',
      bookingDate: admin.firestore.FieldValue.serverTimestamp(),
      status: 'confirmed',
    });

    // Cập nhật ghế đã đặt trong chuyến xe
    const tripRef = db.collection('chuyen_xe').doc(bookingData.tripId);
    const tripDoc = await tripRef.get();
    const tripData = tripDoc.data();
    const updatedSeats = tripData.availableSeats.filter(
      seat => !bookingData.selectedSeats.includes(seat)
    );
    await tripRef.update({ availableSeats: updatedSeats });

    // Xóa đặt vé tạm thời
    await pendingBookingRef.delete();

    // Chuyển hướng người dùng về frontend với trạng thái thành công
    res.redirect('myapp://payment?status=success');
  } else {
    // Thanh toán thất bại
    res.redirect('myapp://payment?status=failure');
  }
});

// API tìm kiếm chuyến xe
app.get('/trips', async (req, res) => {
  const { from, to, date } = req.query;
  const snapshot = await db.collection('chuyen_xe')
    .where('from', '==', from)
    .where('to', '==', to)
    .where('date', '==', date)
    .get();

  const trips = [];
  snapshot.forEach(doc => {
    trips.push({ id: doc.id, ...doc.data() });
  });

  res.json(trips);
});

// API lấy thông tin chuyến xe theo ID
app.get('/trips/:id', async (req, res) => {
  const tripId = req.params.id;
  const tripDoc = await db.collection('chuyen_xe').doc(tripId).get();

  if (!tripDoc.exists) {
    return res.status(404).json({ error: 'Chuyến xe không tồn tại' });
  }

  res.json({ id: tripDoc.id, ...tripDoc.data() });
});

// Hàm sắp xếp object theo key
function sortObject(obj) {
  const sorted = {};
  Object.keys(obj).sort().forEach(key => {
    sorted[key] = obj[key];
  });
  return sorted;
}

app.listen(port, () => {
  console.log(`Server chạy tại http://localhost:${port}`);
});