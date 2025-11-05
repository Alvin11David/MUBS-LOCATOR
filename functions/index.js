const functions = require("firebase-functions");
const { onCall, onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const axios = require("axios");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const gmailEmail =
  process.env.GMAIL_EMAIL || functions.config()?.gmail?.email || "";
const gmailPassword =
  process.env.GMAIL_PASSWORD || functions.config()?.gmail?.password || "";
const googleMapsKey =
  process.env.GOOGLE_MAPS_KEY || functions.config()?.gmaps?.key || "";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user: gmailEmail, pass: gmailPassword },
});

const functionConfig = {
  region: "us-central1",
  timeoutSeconds: 60,
  memory: "256MiB",
  minInstances: 0,
  maxInstances: 10,
  concurrency: 80,
};

// Single export of all functions
module.exports = {
  // PRIVATE: Now onCall – requires logged-in user
  sendOTPEmailV2: onRequest(
    { ...functionConfig, enforceAppCheck: false },
    (req, res) => {
      cors(req, res, async () => {
        try {
          const { email, otp } = req.body || {};

          if (!email || !otp) {
            return res
              .status(400)
              .json({ error: "Email and OTP are required." });
          }

          const lowerEmail = email.toLowerCase().trim();

          // SEND EMAIL
          await transporter.sendMail({
            from: `"MUBS Locator" <${gmailEmail}>`,
            to: lowerEmail,
            subject: "Your MUBS Locator Verification Code",
            text: `Your verification code is: ${otp}`,
          });

          // SAVE TO FIRESTORE
          const docRef = db.collection("password_reset_otp").doc(lowerEmail);
          const now = Date.now();
          const expiresAt = now + 30 * 60 * 1000;

          await docRef.set(
            { email: lowerEmail, otp, createdAt: now, expiresAt },
            { merge: true }
          );

          return res.json({ success: true });
        } catch (err) {
          console.error("sendOTPEmailV2 error:", err);
          return res
            .status(500)
            .json({ error: "Failed to send OTP", details: err.message });
        }
      });
    }
  ),

  // UNCHANGED: Works as before
  sendFeedbackNotification: onDocumentCreated(
    {
      document: "feedback/{feedbackId}",
      ...functionConfig,
    },
    async (event) => {
      const feedback = event.data?.data();
      if (!feedback?.userEmail) return null;

      try {
        const userDoc = await db
          .collection("users")
          .where("email", "==", feedback.userEmail)
          .limit(1)
          .get();

        if (userDoc.empty || !userDoc.docs[0].data().fcmToken) return null;

        await messaging.send({
          token: userDoc.docs[0].data().fcmToken,
          notification: {
            title: "MUBS Locator",
            body: "Thank you! Your feedback has been sent successfully.",
          },
          android: {
            notification: {
              channelId: "mubs_locator_notifications",
              priority: "high",
            },
          },
        });
      } catch (err) {
        console.error("sendFeedbackNotification error:", err);
      }
      return null;
    }
  ),

  sendGlobalNotificationNoAppCheck: onCall(
    {
      ...functionConfig,
      enforceAppCheck: false, // THIS BYPASSES APP CHECK
    },
    async (data, context) => {
      // 1. MUST BE LOGGED IN
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Must be logged in"
        );
      }

      // 2. MUST BE ADMIN
      if (!context.auth.token.admin) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Admin access required"
        );
      }

      // 3. GET DATA
      const category = (data.title || "General").trim();
      const message = (data.body || "").toString().trim();

      // 4. VALIDATE
      if (!message) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Message is required"
        );
      }

      // 5. SEND NOTIFICATION
      try {
        await messaging.send({
          topic: "all_users",
          notification: {
            title: `MUBS: ${category}`,
            body: message,
          },
          android: {
            notification: {
              channelId: "mubs_locator_notifications",
              priority: "high",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        });

        return { success: true, message: "Notification sent!" };
      } catch (err) {
        console.error("FCM Error:", err);
        throw new functions.https.HttpsError("internal", err.message);
      }
    }
  ),

  sendSimpleNotification: onCall(
  { ...functionConfig, enforceAppCheck: false },
  async (data, context) => {
    try {
      // SAFELY read values
      const title = data?.title || "MUBS Locator Update";
      const body = data?.body || "New notification from MUBS Locator!";
      const category = data?.category || "General";

      console.log("Received → title:", title, "| body:", body, "| category:", category);

      const message = {
        topic: "all_users",
        notification: {
          title,
          body,
        },
        android: {
          notification: {
            channelId: "mubs_locator_notifications",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              sound: "default",
              contentAvailable: true,
            },
          },
        },
        data: {
          title,
          body,
          category,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // Send push
      const response = await messaging.send(message);

      console.log("FCM ID:", response);

      return {
        success: true,
        id: response,
        title,
        body,
        category,
      };
    } catch (err) {
      console.error("Send error:", err.message);
      return { success: false, error: err.message };
    }
  }
),


  // UNCHANGED
  sendGlobalNotification: onCall(functionConfig, async (data, context) => {
    // 1. ENFORCE APP CHECK
    if (!context.app) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "App Check failed"
      );
    }

    // 2. MUST BE LOGGED IN
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // 3. MUST BE ADMIN
    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    // 4. GET DATA SAFELY
    const category = (data.title || "General").trim();
    const message = (data.body || "").toString().trim();

    // 5. VALIDATE
    if (!message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Message is required"
      );
    }

    // 6. SEND NOTIFICATION
    try {
      await messaging.send({
        topic: "all_users",
        notification: {
          title: `MUBS: ${category}`,
          body: message,
        },
        android: {
          notification: {
            channelId: "mubs_locator_notifications",
            priority: "high",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      });

      return { success: true, message: "Notification sent!" };
    } catch (err) {
      console.error("FCM Error:", err);
      throw new functions.https.HttpsError("internal", err.message);
    }
  }),

  // UNCHANGED
  sendFeedbackReplyNotification: onCall(
    functionConfig,
    async (data, context) => {
      if (!context.auth?.token?.admin) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Admin required"
        );
      }

      const { userEmail, title, body } = data || {};
      if (!userEmail || !title || !body) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing required fields"
        );
      }

      try {
        const userDoc = await db
          .collection("users")
          .where("email", "==", userEmail)
          .limit(1)
          .get();

        if (userDoc.empty || !userDoc.docs[0].data().fcmToken) {
          throw new functions.https.HttpsError(
            "not-found",
            "User FCM token not found"
          );
        }

        await messaging.send({
          token: userDoc.docs[0].data().fcmToken,
          notification: { title, body },
          android: {
            notification: {
              channelId: "mubs_locator_notifications",
              priority: "high",
            },
          },
        });
        return { success: true };
      } catch (err) {
        throw new functions.https.HttpsError("internal", err.message);
      }
    }
  ),

  // UNCHANGED
  directions: onRequest(functionConfig, async (req, res) => {
    cors(req, res, async () => {
      const { origin, destination } = req.query;
      if (!origin || !destination) {
        return res.status(400).json({ error: "Missing origin or destination" });
      }

      try {
        const { data } = await axios.get(
          `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(
            origin
          )}&destination=${encodeURIComponent(
            destination
          )}&mode=walking&key=${googleMapsKey}`
        );
        res.json(data);
      } catch (err) {
        console.error("directions error:", err);
        res.status(500).json({ error: "Failed to fetch directions" });
      }
    });
  }),
};
