import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'start_up_page.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _saveFcmTokenIfPossible() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final fcm = await FirebaseMessaging.instance.getToken();
    if (fcm == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': fcm,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.requestPermission();
  await _saveFcmTokenIfPossible();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StartupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
