import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized Firestore instance pointing to the active 'default' database
FirebaseFirestore get appFirestore {
  try {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
  } catch (_) {
    return FirebaseFirestore.instance;
  }
}
