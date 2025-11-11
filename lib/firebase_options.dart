import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "demo-key-for-now",
    authDomain: "crime-net-demo.firebaseapp.com",
    projectId: "crime-net-demo",
    storageBucket: "crime-net-demo.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef",
  );
}
