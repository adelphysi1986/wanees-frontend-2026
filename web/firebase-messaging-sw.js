importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCPNGq_n7LS8f82ymhXbt0GiEI5HEcqn4U",
  authDomain: "wanees-52426.firebaseapp.com",
  projectId: "wanees-52426",
  storageBucket: "wanees-52426.firebasestorage.app",
  messagingSenderId: "159001548872",
  appId: "1:159001548872:web:b6cf6adb6983c44995e07d"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {

  console.log(
    "BACKGROUND MESSAGE:",
    payload
  );

  const title =
    payload.notification?.title || "إشعار جديد";

  const options = {
    body:
      payload.notification?.body || "",
    icon:
      "/icons/Icon-192.png",
  };

  self.registration.showNotification(
    title,
    options
  );
});


self.addEventListener(
  "push",
  function(event) {
    console.log("PUSH EVENT");

    event.waitUntil(
      self.registration.showNotification(
        "إشعار جديد",
        {
          body: "وصل إشعار",
          icon: "/icons/Icon-192.png"
        }
      )
    );
  }
);