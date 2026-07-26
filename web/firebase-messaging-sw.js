importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDxLJKqbRORDFp-pVgO2ZOcAee7LboTLlg',
  appId: '1:1015827045951:web:bd6e2b5e0ff49711c9228a',
  messagingSenderId: '1015827045951',
  projectId: 'meetingbuds',
  authDomain: 'meetingbuds.firebaseapp.com',
  storageBucket: 'meetingbuds.firebasestorage.app',
});

const messaging = firebase.messaging();

// Handles notifications that arrive while the web tab is closed or
// in the background. Foreground messages are handled in Dart instead.
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Meet Buddies';
  const options = {
    body: payload.notification?.body || '',
    icon: '/favicon.png',
  };
  self.registration.showNotification(title, options);
});