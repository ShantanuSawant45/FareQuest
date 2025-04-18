// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCl9PRrpyaqosT-RsXGwu61nX0OP0oUo3c',
    appId: '1:398893810547:web:4149fff5a31fd8bc293b06',
    messagingSenderId: '398893810547',
    projectId: 'farequest-1c71d',
    authDomain: 'farequest-1c71d.firebaseapp.com',
    storageBucket: 'farequest-1c71d.firebasestorage.app',
    measurementId: 'G-Q00M88C2LV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAfs9OHpL1wo-1W6NIyDPD68fBx8VBbY4',
    appId: '1:398893810547:android:48e5e546774178f4293b06',
    messagingSenderId: '398893810547',
    projectId: 'farequest-1c71d',
    storageBucket: 'farequest-1c71d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbHDW18WULfZBEc7nXtRBXJhDdztFDlkQ',
    appId: '1:398893810547:ios:17f66445dd48667e293b06',
    messagingSenderId: '398893810547',
    projectId: 'farequest-1c71d',
    storageBucket: 'farequest-1c71d.firebasestorage.app',
    iosBundleId: 'com.example.seProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDbHDW18WULfZBEc7nXtRBXJhDdztFDlkQ',
    appId: '1:398893810547:ios:17f66445dd48667e293b06',
    messagingSenderId: '398893810547',
    projectId: 'farequest-1c71d',
    storageBucket: 'farequest-1c71d.firebasestorage.app',
    iosBundleId: 'com.example.seProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCl9PRrpyaqosT-RsXGwu61nX0OP0oUo3c',
    appId: '1:398893810547:web:4bd8edc41747fcec293b06',
    messagingSenderId: '398893810547',
    projectId: 'farequest-1c71d',
    authDomain: 'farequest-1c71d.firebaseapp.com',
    storageBucket: 'farequest-1c71d.firebasestorage.app',
    measurementId: 'G-XXGZ22E1CS',
  );
}
