const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

// Use Firebase config for Gmail credentials
const gmailEmail = functions.config().gmail.email;
const gmailPassword = functions.config().gmail.password;

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// Force 1st Gen and set region to us-central1
exports.sendOTPEmail = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const email = data.email;
    const otp = data.otp;

    if (!email || !otp) {
      throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required.');
    }

    const mailOptions = {
      from: `"MUBS Locator" <${gmailEmail}>`,
      to: email,
      subject: 'Your MUBS Locator Verification Code',
      text: `Hello,

Your 4-digit verification code for MUBS Locator is: ${otp}

Enter this code in the app to continue.

If you did not request this, please ignore this email.

Thanks,
The MUBS Locator Team`,
    };

    try {
      await transporter.sendMail(mailOptions);
      return { success: true };
    } catch (error) {
      throw new functions.https.HttpsError('internal', error.message);
    }
  });