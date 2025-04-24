import 'package:firebase_core/firebase_core.dart';
import 'package:tuan_hung/firebase_options.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
