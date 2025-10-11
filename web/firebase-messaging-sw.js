// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

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

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/logo.png', // Ensure this file exists in web/
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});