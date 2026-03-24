importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// You can get this object from the Firebase Console.
firebase.initializeApp({
  apiKey: "AIzaSyCq31TfSN_aa9YkfCQ8JHXFC5F9iPXwKZI",
  authDomain: "al-graphy-pro.firebaseapp.com",
  projectId: "al-graphy-pro",
  storageBucket: "al-graphy-pro.firebasestorage.app",
  messagingSenderId: "620504539920",
  appId: "1:620504539920:web:f0ae5c4b8c208d93bbbb95"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle,
    notificationOptions);
});
