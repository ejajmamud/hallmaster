import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hallmaster_enterprise/firebase_options.dart';
import 'package:hallmaster_enterprise/src/app/app.dart';
import 'package:hallmaster_enterprise/src/core/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirestoreService().ensureSeeded();
  } catch (error) {
    debugPrint('Firestore seed skipped: $error');
  }
  runApp(const ProviderScope(child: HallMasterApp()));
}
