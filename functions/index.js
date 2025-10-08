const functions = require('firebase-functions');
const nodemailer = require('nodemailer');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Gmail credentials for OTP email
const gmailEmail = functions.config().gmail.email;
const gmailPassword = functions.config().gmail.password;

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// Existing OTP email function
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

// New function to send FCM notification on feedback submission
exports.sendFeedbackNotification = functions
  .region('us-central1') // Match region with sendOTPEmail
  .firestore
  .document('feedback/{feedbackId}')
  .onCreate(async (snap, context) => {
    const feedbackData = snap.data();
    const userEmail = feedbackData.userEmail;

    // Fetch user’s FCM token from the users collection
    const userQuery = await admin.firestore()
      .collection('users')
      .where('email', '==', userEmail)
      .limit(1)
      .get();

    if (userQuery.empty) {
      console.log('No user found with email:', userEmail);
      return null;
    }

    const userDoc = userQuery.docs[0];
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', userEmail);
      return null;
    }

    // Define the notification payload
    const message = {
      notification: {
        title: 'MUBS Locator',
        body: 'Thank you! Your feedback has been sent successfully.',
      },
      token: fcmToken,
    };

    // Send the notification
    try {
      await admin.messaging().send(message);
      console.log('Notification sent to:', userEmail);
      return null;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });