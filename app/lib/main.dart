import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bap_pulse/app.dart';
import 'package:bap_pulse/firebase_options.dart';
import 'package:bap_pulse/notifications/data/fcm_service.dart';

/// Top-level background message handler. Required by firebase_messaging on
/// Android — the OS spins up an isolated Dart isolate to run this when a
/// message arrives while the app is killed. Must be a top-level function,
/// annotated `vm:entry-point` for tree-shaking.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // The system already shows the notification banner from the payload; no
  // additional work is needed here. Kept around as the wire-up point if we
  // later need to update an offline cache or local notification badge.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await initializeDateFormatting('fr_FR');
  // FcmService.init() is also idempotently called by registerCurrentToken on
  // sign-in; running it eagerly here means permission prompts fire at launch
  // for already-authenticated users, which is what we want.
  await FcmService.instance.init();
  runApp(const App());
}
