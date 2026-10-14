import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Using dummy options since emulator doesn't strictly need real ones if initialized properly
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'dummy',
      appId: 'dummy',
      messagingSenderId: 'dummy',
      projectId: 'demo-rahhal',
    ),
  );
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

  try {
    final qs = await FirebaseFirestore.instance
        .collection('support_tickets')
        .where('category', isEqualTo: 'passenger')
        .where('status', whereIn: ['open', 'processing', 'waiting'])
        .orderBy('createdAt', descending: true)
        .get();
    debugPrint('FIRESTORE_SUCCESS! Docs: ${qs.docs.length}');
  } catch (e) {
    debugPrint('FIRESTORE_ERROR: $e');
  }
}
