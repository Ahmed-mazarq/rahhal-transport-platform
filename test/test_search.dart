import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rahal/firebase_options.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('trips').get();

  debugPrint('Found ${snapshot.docs.length} trips in firestore');

  for (var doc in snapshot.docs) {
    debugPrint('Testing doc: ${doc.id}');
    try {
      final data = doc.data();
      final trip = Trip.fromJson(data);
      debugPrint('  -> Parsed successfully: ${trip.id}');
    } catch (e, stack) {
      debugPrint('  -> FAILED: $e');
      debugPrint(stack.toString());
    }
  }
  debugPrint('Done testing Trip.fromJson()');
}
