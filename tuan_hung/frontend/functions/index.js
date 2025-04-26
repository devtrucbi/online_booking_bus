const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const config = functions.config();
const gmailEmail = config.gmail ? config.gmail.email : undefined;
const gmailPassword = config.gmail ? config.gmail.password : undefined;

let transporter;
if (gmailEmail && gmailPassword) {
    transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
            user: gmailEmail,
            pass: gmailPassword,
        },
    });
} else {
    console.warn("Missing Gmail configuration. Email sending will fail until gmail.email and gmail.password are set using 'firebase functions:config:set'.");
}

exports.sendWelcomeEmail = functions
    .firestore
    .document("users/{userId}")
    .onCreate(async (snap, context) => {
        if (!transporter) {
            throw new Error("Gmail configuration is missing. Cannot send email.");
        }

        const user = snap.data();
        const email = user.email;
        const name = user.name;

        const mailOptions = {
            from: gmailEmail,
            to: email,
            subject: "Chào mừng đến với Tuấn Hưng Bus!",
            text: `Xin chào ${name},\n\nCảm ơn bạn đã đăng ký tài khoản tại Tuấn Hưng Bus. Tài khoản của bạn đã được tạo thành công!\n\nTrân trọng,\nTuấn Hưng Bus`,
            html: `<h3>Xin chào ${name},</h3><p>Cảm ơn bạn đã đăng ký tài khoản tại Tuấn Hưng Bus. Tài khoản của bạn đã được tạo thành công!</p><p>Trân trọng,<br>Tuấn Hưng Bus</p>`,
        };

        try {
            await transporter.sendMail(mailOptions);
            console.log("Email xác nhận đã được gửi đến:", email);
            return null;
        } catch (error) {
            console.error("Lỗi khi gửi email:", error);
            throw new functions.https.HttpsError("internal", "Không thể gửi email xác nhận");
        }
    });
