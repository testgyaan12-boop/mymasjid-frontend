import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBmYMiooGT1-YyJTLWH4qIvgKmrGarxYDA',
    appId: '1:491011458887:android:47dd147c20e19a585e2e62',
    messagingSenderId: '491011458887',
    projectId: 'studio-5179544815-8063e',
    storageBucket: 'studio-5179544815-8063e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmYMiooGT1-YyJTLWH4qIvgKmrGarxYDA',
    appId: '1:491011458887:android:47dd147c20e19a585e2e62',
    messagingSenderId: '491011458887',
    projectId: 'studio-5179544815-8063e',
    storageBucket: 'studio-5179544815-8063e.firebasestorage.app',
    iosBundleId: 'com.nooralmasjid.noorAlMasjid',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmYMiooGT1-YyJTLWH4qIvgKmrGarxYDA',
    appId: '1:491011458887:android:47dd147c20e19a585e2e62',
    messagingSenderId: '491011458887',
    projectId: 'studio-5179544815-8063e',
    storageBucket: 'studio-5179544815-8063e.firebasestorage.app',
    iosBundleId: 'com.nooralmasjid.noorAlMasjid',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBmYMiooGT1-YyJTLWH4qIvgKmrGarxYDA',
    appId: '1:491011458887:android:47dd147c20e19a585e2e62',
    messagingSenderId: '491011458887',
    projectId: 'studio-5179544815-8063e',
    storageBucket: 'studio-5179544815-8063e.firebasestorage.app',
  );
}