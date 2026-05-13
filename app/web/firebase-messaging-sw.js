// Background FCM service worker for the Flutter web build.
// Registered automatically by firebase_messaging at /firebase-messaging-sw.js.
//
// Mirrors the web Firebase options from lib/firebase_options.dart.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDzF_sisS1ilx0cMIrAoUi-GHQ_iCRdaII',
  appId: '1:239139234503:web:56c523f8178ad66a2fd4e2',
  messagingSenderId: '239139234503',
  projectId: 'bap-pulse',
  authDomain: 'bap-pulse.firebaseapp.com',
  storageBucket: 'bap-pulse.firebasestorage.app',
});

const messaging = firebase.messaging();

// onBackgroundMessage handler — fires when the tab is closed/backgrounded.
// We don't show a custom notification here because the API sends data+notification
// payloads; the browser surfaces the notification block automatically. If we ever
// switch to data-only payloads, build the notification manually here.
messaging.onBackgroundMessage((payload) => {
  // No-op: notification payload is rendered by the browser.
  // Keeping the handler defined silences "no listener" warnings in DevTools.
  void payload;
});
