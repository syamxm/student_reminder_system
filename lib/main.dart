import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '958691525428-ic7ht1ntcn24b3qf8ome5ld3l021b7t4.apps.googleusercontent.com',
    );
  }

  runApp(const StudentReminderApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.init().catchError((error, stackTrace) {
      log(
        'NotificationService init failed',
        error: error,
        stackTrace: stackTrace,
      );
    });
  });
}
