// File generated manually for Firebase project wanees-52426

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase configuration not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCPNGq_n7LS8f82ymhXbt0GiEI5HEcqn4U',
    authDomain: 'wanees-52426.firebaseapp.com',
    projectId: 'wanees-52426',
    storageBucket: 'wanees-52426.firebasestorage.app',
    messagingSenderId: '159001548872',
    appId: '1:159001548872:web:b6cf6adb6983c44995e07d',
    measurementId: 'G-1W7R575CHW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCPNGq_n7LS8f82ymhXbt0GiEI5HEcqn4U',
    appId: '1:159001548872:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '159001548872',
    projectId: 'wanees-52426',
    storageBucket: 'wanees-52426.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCPNGq_n7LS8f82ymhXbt0GiEI5HEcqn4U',
    appId: '1:159001548872:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '159001548872',
    projectId: 'wanees-52426',
    storageBucket: 'wanees-52426.firebasestorage.app',
  );
}
