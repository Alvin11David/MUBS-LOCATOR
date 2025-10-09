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

// Function to send OTP email
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

// Function to send FCM notification on feedback submission
exports.sendFeedbackNotification = functions
  .region('us-central1')
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
      android: {
        notification: {
          channelId: 'mubs_locator_notifications', // Match Android channel
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: 'MUBS Locator',
              body: 'Thank you! Your feedback has been sent successfully.',
            },
            sound: 'default',
            contentAvailable: true,
          },
        },
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
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

// Function to send global notification to all_users topic
exports.sendGlobalNotification = functions
  .region('us-central1') // Match region with other functions
  .https.onCall(async (data, context) => {
    // Verify the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }

    // Verify admin role (assumes custom claim 'admin' is set)
    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required.');
    }

    const { title, body, category } = data;

    const message = {
      notification: {
        title: title || 'MUBS Locator Update',
        body: body || 'New notification from MUBS Locator!',
      },
      topic: 'all_users',
      android: {
        notification: {
          channelId: 'mubs_locator_notifications', // Match Android channel
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title || 'MUBS Locator Update',
              body: body || 'New notification from MUBS Locator!',
            },
            sound: 'default',
            contentAvailable: true,
          },
        },
      },
      data: {
        category: category || 'General',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    try {
      await admin.messaging().send(message);
      return { success: true, message: 'Notification sent to all users.' };
    } catch (error) {
      throw new functions.https.HttpsError('internal', `Error sending notification: ${error.message}`);
    }
  });