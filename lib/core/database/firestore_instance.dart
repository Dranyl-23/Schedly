import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore instance pointing to the active default database
FirebaseFirestore get appFirestore {
  return FirebaseFirestore.instance;
}
