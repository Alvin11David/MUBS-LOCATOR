// Import the Firebase Messaging scripts
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging.js');

// Initialize Firebase
const firebaseConfig = {
  apiKey: "AIzaSyDKGTdWstqbR6wn-Y81PdRcsnFvPYH5nso",
  authDomain: "mubs-locator.firebaseapp.com",
  projectId: "mubs-locator",
  storageBucket: "mubs-locator.firebasestorage.app",
  messagingSenderId: "700901312627",
  appId: "1:700901312627:web:c2dfd9dcd0d03865050206",
  measurementId: "G-8P9GNWXC5Q",
};

firebase.initializeApp(firebaseConfig);

// Initialize Firebase Cloud Messaging
const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/logo.png', // Replace with your app's icon
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});