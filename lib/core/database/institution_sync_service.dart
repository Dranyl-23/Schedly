import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/institution_directory.dart';

class InstitutionSyncService {
  static final InstitutionSyncService _instance = InstitutionSyncService._internal();
  factory InstitutionSyncService() => _instance;
  InstitutionSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void startListening() {
    try {
      _firestore.collection('institutions').snapshots().listen((snapshot) {
        final List<InstitutionItem> cloudList = [];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final item = InstitutionItem.fromFirestore(data, doc.id);
            cloudList.add(item);
          } catch (e) {
            debugPrint('Error parsing institution doc ${doc.id}: $e');
          }
        }
        InstitutionItem.setCloudInstitutions(cloudList);
        debugPrint('InstitutionSyncService: Synced ${cloudList.length} dynamic institutions from cloud.');
      }, onError: (e) {
        debugPrint('InstitutionSyncService snapshot error: $e');
      });
    } catch (e) {
      debugPrint('Failed to start InstitutionSyncService: $e');
    }
  }
}
